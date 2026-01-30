from __future__ import annotations

import base64
import hashlib
import json
import os
import subprocess
import tempfile
import zipfile
from pathlib import Path
from typing import Dict, List, Optional

from fastapi import FastAPI, File, HTTPException, UploadFile
from fastapi.responses import Response
from pydantic import BaseModel

app = FastAPI(title="Pass Signer", version="1.0.0")


class FilePayload(BaseModel):
    name: str
    data: str


class SignRequest(BaseModel):
    passJson: str
    files: List[FilePayload]


class HealthResponse(BaseModel):
    status: str
    version: str


class SignerConfig:
    def __init__(self) -> None:
        self.pass_cert_p12_path = os.environ.get("PASS_CERT_P12_PATH")
        self.pass_cert_p12_password = os.environ.get("PASS_CERT_P12_PASSWORD")
        self.wwdr_cert_path = os.environ.get("WWDR_CERT_PATH")
        self.pass_type_identifier = os.environ.get("PASS_TYPE_IDENTIFIER")
        self.team_identifier = os.environ.get("TEAM_IDENTIFIER")
        self.organization_name = os.environ.get("ORGANIZATION_NAME", "")

    def validate(self) -> None:
        missing = []
        if not self.pass_cert_p12_path:
            missing.append("PASS_CERT_P12_PATH")
        if not self.pass_cert_p12_password:
            missing.append("PASS_CERT_P12_PASSWORD")
        if not self.wwdr_cert_path:
            missing.append("WWDR_CERT_PATH")
        if not self.pass_type_identifier:
            missing.append("PASS_TYPE_IDENTIFIER")
        if not self.team_identifier:
            missing.append("TEAM_IDENTIFIER")
        if missing:
            raise HTTPException(status_code=500, detail={"code": "config_missing", "message": ", ".join(missing)})


@app.get("/health", response_model=HealthResponse)
async def health() -> HealthResponse:
    return HealthResponse(status="ok", version=app.version)


@app.post("/sign-pass")
async def sign_pass(
    request: Optional[SignRequest] = None,
    pass_json: Optional[UploadFile] = File(default=None, alias="pass.json"),
    files: Optional[List[UploadFile]] = File(default=None),
) -> Response:
    config = SignerConfig()
    config.validate()

    try:
        if request:
            pass_json_bytes = base64.b64decode(request.passJson)
            file_map = {payload.name: base64.b64decode(payload.data) for payload in request.files}
        elif pass_json:
            pass_json_bytes = await pass_json.read()
            file_map = {}
            if files:
                for upload in files:
                    file_map[upload.filename] = await upload.read()
        else:
            raise HTTPException(status_code=400, detail={"code": "invalid_request", "message": "Missing pass.json"})

        if not pass_json_bytes:
            raise HTTPException(status_code=400, detail={"code": "invalid_pass_json", "message": "pass.json is empty"})

        pass_data = json.loads(pass_json_bytes.decode("utf-8"))
        if pass_data.get("passTypeIdentifier") != config.pass_type_identifier:
            raise HTTPException(status_code=400, detail={"code": "pass_type_mismatch", "message": "passTypeIdentifier mismatch"})
        if pass_data.get("teamIdentifier") != config.team_identifier:
            raise HTTPException(status_code=400, detail={"code": "team_id_mismatch", "message": "teamIdentifier mismatch"})

        pkpass = build_pkpass(pass_json_bytes, file_map, config)
        return Response(content=pkpass, media_type="application/vnd.apple.pkpass")
    except HTTPException as exc:
        raise exc
    except Exception as exc:
        raise HTTPException(status_code=500, detail={"code": "sign_failed", "message": str(exc)}) from exc


def build_pkpass(pass_json_bytes: bytes, file_map: Dict[str, bytes], config: SignerConfig) -> bytes:
    with tempfile.TemporaryDirectory() as temp_dir:
        temp_path = Path(temp_dir)
        (temp_path / "pass.json").write_bytes(pass_json_bytes)
        for name, data in file_map.items():
            (temp_path / name).write_bytes(data)

        manifest = compute_manifest(temp_path)
        (temp_path / "manifest.json").write_text(json.dumps(manifest, indent=2, sort_keys=True))

        cert_path, key_path = extract_cert_and_key(config, temp_path)
        signature_path = temp_path / "signature"

        run_openssl_sign(cert_path, key_path, config.wwdr_cert_path, temp_path / "manifest.json", signature_path)

        pkpass_bytes = create_zip_bytes(temp_path)
        return pkpass_bytes


def compute_manifest(pass_dir: Path) -> Dict[str, str]:
    manifest: Dict[str, str] = {}
    for file_path in pass_dir.iterdir():
        if file_path.name in {"manifest.json", "signature"}:
            continue
        if file_path.is_file():
            digest = hashlib.sha1(file_path.read_bytes()).hexdigest()
            manifest[file_path.name] = digest
    return manifest


def extract_cert_and_key(config: SignerConfig, temp_path: Path) -> tuple[Path, Path]:
    cert_path = temp_path / "pass_cert.pem"
    key_path = temp_path / "pass_key.pem"

    subprocess.run(
        [
            "openssl",
            "pkcs12",
            "-in",
            config.pass_cert_p12_path,
            "-clcerts",
            "-nokeys",
            "-out",
            str(cert_path),
            "-passin",
            f"pass:{config.pass_cert_p12_password}",
        ],
        check=True,
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
    )

    subprocess.run(
        [
            "openssl",
            "pkcs12",
            "-in",
            config.pass_cert_p12_path,
            "-nocerts",
            "-out",
            str(key_path),
            "-passin",
            f"pass:{config.pass_cert_p12_password}",
            "-passout",
            f"pass:{config.pass_cert_p12_password}",
        ],
        check=True,
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
    )

    return cert_path, key_path


def run_openssl_sign(cert_path: Path, key_path: Path, wwdr_cert_path: str, manifest_path: Path, signature_path: Path) -> None:
    subprocess.run(
        [
            "openssl",
            "smime",
            "-binary",
            "-sign",
            "-certfile",
            wwdr_cert_path,
            "-signer",
            str(cert_path),
            "-inkey",
            str(key_path),
            "-in",
            str(manifest_path),
            "-out",
            str(signature_path),
            "-outform",
            "DER",
        ],
        check=True,
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
    )


def create_zip_bytes(pass_dir: Path) -> bytes:
    zip_path = pass_dir / "pass.pkpass"
    with zipfile.ZipFile(zip_path, "w", compression=zipfile.ZIP_DEFLATED) as zip_file:
        for file_path in pass_dir.iterdir():
            if file_path.is_file() and file_path.name != "pass.pkpass":
                zip_file.write(file_path, arcname=file_path.name)
    return zip_path.read_bytes()
