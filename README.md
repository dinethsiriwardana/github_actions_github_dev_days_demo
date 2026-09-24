# GitHub Actions Demo: Docker Build & Push CI/CD Pipeline 🚀

Welcome to the GitHub Actions demo project! This repository serves as a step-by-step guide and live demonstration of how to build an optimized, secure, and highly scalable CI/CD pipeline using GitHub Actions to containerize a Node.js application and push it to Docker Hub.

---

## 📖 Project Overview

This is a simple Node.js Express application that we use as the foundation for our CI/CD demonstration. The true focus of this repository is its **GitHub Actions workflow**, which evolves progressively through multiple stages to demonstrate industry best practices.

### 🛠️ Tech Stack
- **Application**: Node.js, Express
- **Containerization**: Docker
- **CI/CD**: GitHub Actions
- **Registry**: Docker Hub

---

## 🚀 The Pipeline Evolution (Stages)

This repository's CI/CD pipeline is designed to be built in stages. Each stage represents a specific Pull Request (`stage-X`) that introduces a new concept or optimization to the workflow.

### Stage 0: The Baseline 
A basic, unoptimized workflow that checks out the code, logs into Docker Hub, and builds/pushes an image. It gets the job done but lacks security, speed, and cross-platform support.

### Stage 1: Secrets & Variables 🔐
Introduces GitHub **Secrets** and **Repository Variables** (`vars`) to safely authenticate with Docker Hub and dynamically assign repository names without hardcoding sensitive information into the workflow.

### Stage 2: Layer Caching ⚡
Dramatically speeds up the workflow by introducing Docker's `cache-from` and `cache-to` properties using the GitHub Actions cache (`type=gha`). Subsequent builds avoid re-downloading dependencies and reinstalling heavy native packages.

### Stage 3: Multi-Arch Matrix Native Builds 🏗️
Expands the pipeline to support multiple CPU architectures (`linux/amd64` and `linux/arm64`). Instead of using slow QEMU emulation, this stage utilizes a **Matrix Strategy** paired with GitHub's native `ubuntu-24.04-arm` hosted runners to build architectures concurrently at maximum speed, outputting separate architectural tags (`latest-amd64` and `latest-arm64`).

### Stage 4: Least-Privilege Security 🛡️
Adopts the principle of least privilege by explicitly setting `permissions: contents: read` in the workflow. This ensures the `GITHUB_TOKEN` only has the exact permissions it needs and prevents malicious actors from exploiting the pipeline.

### Stage 5: Composite Actions 🧩
Refactors the bloated workflow by extracting the Docker setup, login, and build steps into a reusable **Composite Action** (`.github/actions/docker-build-push/action.yml`). This makes the main workflow clean, declarative, and easy to maintain.

---

## 💻 Running the App Locally

If you want to run the Node.js application locally on your machine:

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

## 🐳 Building with Docker

To manually build and run the Docker container locally:

1. **Build the image:**
   ```bash
   docker build -t demo-app:latest .
   ```

2. **Run the container:**
   ```bash
   docker run -p 3000:3000 demo-app:latest
   ```

---

## ⚙️ CI/CD Setup Prerequisites 

If you are forking this repository to run your own pipelines, you must configure the following in your GitHub Repository settings (`Settings > Secrets and variables > Actions`):

**Secrets:**
- `DOCKERHUB_USERNAME`: Your Docker Hub username.
- `DOCKERHUB_TOKEN`: Your Docker Hub Personal Access Token (PAT).

**Variables:**
- `DOCKERHUB_REPO`: The namespace and repository name on Docker Hub (e.g., `yourusername/demo-app`).
