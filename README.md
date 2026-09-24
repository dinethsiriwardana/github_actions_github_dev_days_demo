# GitHub Actions Demo: Docker Build & Push CI/CD Pipeline 🚀

Welcome to the GitHub Actions demo project! This repository serves as a step-by-step guide and live demonstration of how to build an optimized, secure, and highly scalable CI/CD pipeline using GitHub Actions to containerize a Node.js application and push it to Docker Hub.

---

## 📖 Project Overview

This is a simple Node.js Express application. The true focus of this repository is its **GitHub Actions workflow**, which evolves progressively through multiple stages (branches) to demonstrate industry best practices.

### 🛠️ Tech Stack
- **Application**: Node.js, Express
- **Containerization**: Docker
- **CI/CD**: GitHub Actions
- **Registry**: Docker Hub

---

## 🎓 Full Tutorial Guide: The Pipeline Evolution

This repository's CI/CD pipeline is designed to be built in stages. Each stage represents a specific Pull Request (`stage-X`) that introduces a new concept or optimization to the workflow. Below is a detailed explanation of the code and concepts introduced in each stage.

### Stage 0: The Baseline (`stage-0-baseline`)
We start with a basic, unoptimized workflow that checks out the code, logs into Docker Hub, and builds/pushes an image. It gets the job done but lacks security, speed, and cross-platform support.

```yaml
name: Release
on:
  push:
    branches: [release]

jobs:
  build-and-push:
    runs-on: ubuntu-latest
    steps:
      # 1. Check out the repository code
      - uses: actions/checkout@v4

      # 2. Login to Docker Hub
      - uses: docker/login-action@v3
        with:
          username: ${{ secrets.DOCKERHUB_USERNAME }}
          password: ${{ secrets.DOCKERHUB_TOKEN }}

      # 3. Build and push the Docker image
      - uses: docker/build-push-action@v6
        with:
          push: true
          tags: ${{ vars.DOCKERHUB_REPO }}:latest
```
* **`actions/checkout@v4`**: Pulls your source code into the runner environment.
* **`docker/login-action` & `docker/build-push-action`**: Official Docker actions to authenticate and build/push the image.

---

### Stage 1: Secrets & Variables (`stage-1-secrets`)
Hardcoding sensitive data (like passwords) or environment-specific data (like repository names) is a bad practice. Here, we rely on GitHub **Secrets** and **Repository Variables** (`vars`).

* **Secrets (`secrets.DOCKERHUB_TOKEN`)**: Used for highly sensitive information. It is masked in the logs and cannot be retrieved once saved.
* **Variables (`vars.DOCKERHUB_REPO`)**: Used for non-sensitive configuration data (e.g., `yourusername/demo-app`). This makes the workflow easily reusable by simply changing the repository variables in GitHub settings, rather than modifying the code.

---

### Stage 2: Layer Caching (`stage-2-caching`)
Docker builds can be slow, especially when installing heavy native dependencies (like `ffmpeg`, `g++`, etc. in our Dockerfile). We speed this up by introducing Docker's `cache-from` and `cache-to` properties using the GitHub Actions cache backend (`type=gha`).

```yaml
    steps:
      - uses: actions/checkout@v4
      
      # NEW: Required to enable advanced buildkit features like caching
      - uses: docker/setup-buildx-action@v3

      - uses: docker/login-action@v3
        with:
          username: ${{ secrets.DOCKERHUB_USERNAME }}
          password: ${{ secrets.DOCKERHUB_TOKEN }}

      - uses: docker/build-push-action@v6
        with:
          push: true
          tags: ${{ vars.DOCKERHUB_REPO }}:latest
          # NEW: Read from and write to the GitHub Actions cache
          cache-from: type=gha
          cache-to: type=gha,mode=max
```
* **`setup-buildx-action`**: Installs Docker Buildx, which is the next-generation Docker builder required for advanced caching.
* **`type=gha`**: Tells Buildx to use the GitHub Actions Cache API to store Docker layers.
* **`mode=max`**: Ensures that *all* layers are cached, not just the ones used in the final resulting image.

---

### Stage 3: Multi-Arch Matrix Native Builds (`stage-3-matrix`)
Modern applications need to run on multiple CPU architectures (e.g., Intel/AMD and Apple Silicon/ARM). We use a **Matrix Strategy** to build both concurrently. To ensure maximum speed, we use GitHub's native ARM runners instead of slow QEMU emulation.

```yaml
  build-and-push:
    strategy:
      matrix:
        include:
          - platform: linux/amd64
            tag_suffix: amd64
            runner: ubuntu-latest       # Native x86_64 runner
          - platform: linux/arm64
            tag_suffix: arm64
            runner: ubuntu-24.04-arm    # Native ARM64 runner
            
    # NEW: Dynamically assign the runner based on the matrix
    runs-on: ${{ matrix.runner }}
    steps:
      # ... checkout, buildx, login ...

      - uses: docker/build-push-action@v6
        with:
          platforms: ${{ matrix.platform }}
          push: true
          tags: ${{ vars.DOCKERHUB_REPO }}:latest-${{ matrix.tag_suffix }}
          
          # NEW: Scope the cache to prevent matrix jobs from overwriting each other!
          cache-from: type=gha,scope=${{ github.workflow }}-${{ matrix.platform }}
          cache-to: type=gha,mode=max,scope=${{ github.workflow }}-${{ matrix.platform }}
```
* **Matrix Strategy**: Spawns multiple identical jobs that run in parallel, substituting the variables (`platform`, `runner`) for each combination.
* **Native Runners**: Using `ubuntu-24.04-arm` completely bypasses the need for QEMU emulation, cutting ARM build times down by over 80%.
* **Cache Scoping**: **CRITICAL!** Because both matrix jobs share the same job name, they would normally overwrite each other's cache manifests. We append `${{ matrix.platform }}` to the cache `scope` to keep them isolated.

---

### Stage 4: Least-Privilege Security (`stage-4-security`)
By default, the `GITHUB_TOKEN` provided to your workflow might have broad write permissions to your repository. We apply the principle of least privilege by explicitly restricting it.

```yaml
name: Release
on:
  push:
    branches: [release]

# NEW: Restrict the GITHUB_TOKEN to only have read access to the repository contents.
permissions:
  contents: read

jobs:
# ...
```
* **`permissions: contents: read`**: Explicitly defines that the workflow can only *read* the code. It strips away write permissions to code, PRs, issues, and packages, preventing a compromised dependency from using the CI token maliciously.

---

### Stage 5: Composite Actions & Artifacts (`stage-5-composite-action`)
As our workflow grows, we can bundle steps into **Composite Actions** to make them reusable and our main workflow cleaner. In this stage, we also introduce **GitHub Actions Artifacts** to capture and attach build logs directly to the workflow run.

**1. The Reusable Action (`.github/actions/upload-build-report/action.yml`):**
```yaml
name: 'Upload Build Report'
description: 'Generates a build report and uploads it as an artifact'
inputs:
  platform:
    description: 'The platform that was built'
    required: true
runs:
  using: "composite"
  steps:
    - name: Generate Report
      run: |
        echo "Build Report" > build-report.txt
        echo "====================" >> build-report.txt
        echo "Successfully built Docker image for platform: ${{ inputs.platform }}" >> build-report.txt
        echo "Build completed at: $(date)" >> build-report.txt
      shell: bash
    - name: Upload Artifact
      uses: actions/upload-artifact@v4
      with:
        name: build-report-${{ inputs.platform }}
        path: build-report.txt
```

**2. The Cleaned-Up Workflow (`.github/workflows/release.yml`):**
```yaml
    steps:
      - uses: actions/checkout@v4
      
      # ... Docker setup, login, and build-push steps ...

      # NEW: Call our custom composite action to generate and upload the report!
      - uses: ./.github/actions/upload-build-report
        with:
          platform: ${{ matrix.tag_suffix }}
```
* **Composite Actions**: We created a custom action that encapsulates bash scripting and third-party actions (`upload-artifact`) into one neat, reusable component. 
* **Artifacts**: Once the workflow finishes, you can download `build-report-amd64.zip` and `build-report-arm64.zip` directly from the GitHub Actions summary page!

---

## 💻 Running the App Locally

1. **Clone the repository:**
   ```bash
   git clone https://github.com/dinethsiriwardana/github_actions.git
   cd github_actions
   ```

2. **Install dependencies:**
   ```bash
   npm install
   ```

3. **Start the server:**
   ```bash
   node server.js
   ```
   *The server will start on http://localhost:3000.*

---

## ⚙️ CI/CD Setup Prerequisites 

If you are forking this repository to run your own pipelines, you must configure the following in your GitHub Repository settings (`Settings > Secrets and variables > Actions`):

**Secrets:**
- `DOCKERHUB_USERNAME`: Your Docker Hub username.
- `DOCKERHUB_TOKEN`: Your Docker Hub Personal Access Token (PAT).

**Variables:**
- `DOCKERHUB_REPO`: The namespace and repository name on Docker Hub (e.g., `yourusername/demo-app`).
