# Version policy

Pin important dependencies and container images. Never deploy latest.

For updates, record current/proposed versions, upstream release notes, architecture/kernel compatibility, backup status, rollback, and acceptance tests. For NVIDIA, check Pascal support, kernel, CUDA, host GPU access, container GPU access, reboot, and post-reboot tests.

versions.yml records candidate releases observed 2026-09-30. They are not proof of compatibility or authorization to deploy. Verify image tags and test on the target before adding Compose projects. Record the tested Ubuntu kernel, NVIDIA driver, Container Toolkit, and CUDA container as one tuple.
