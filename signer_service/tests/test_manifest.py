from pathlib import Path

from app.main import compute_manifest


def test_manifest_sha1_generation(tmp_path: Path) -> None:
    (tmp_path / "pass.json").write_text("{}")
    (tmp_path / "icon.png").write_bytes(b"icon")

    manifest = compute_manifest(tmp_path)

    assert manifest["pass.json"] == "bf21a9e8fbc5a3846fb05b4fa0859e0917b2202f"
    assert manifest["icon.png"] == "f8995ba5891b07e328c60d6bd6c10159878c5a13"
