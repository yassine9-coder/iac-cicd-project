# Jenkins setup notes

Exact commands used to get Jenkins running with the ability to control Docker on the host and execute
this project's pipeline.

## 1. Run Jenkins with Docker socket access

```bash
docker run -d --name jenkins \
  -p 8082:8080 -p 50000:50000 \
  -v jenkins_home:/var/jenkins_home \
  -v /var/run/docker.sock:/var/run/docker.sock \
  jenkins/jenkins:lts
```

Get the initial admin password:
```bash
sleep 20
docker exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword
```

Complete the setup wizard in the browser (install suggested plugins, create an admin user).

## 2. Install Terraform, Ansible, and the Docker CLI inside the Jenkins container

Jenkins is isolated from the host and has none of these tools by default:

```bash
docker exec -u root jenkins bash -c "
apt-get update &&
apt-get install -y curl gnupg lsb-release ansible &&
curl -fsSL https://apt.releases.hashicorp.com/gpg | gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg &&
echo 'deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com \$(lsb_release -cs) main' | tee /etc/apt/sources.list.d/hashicorp.list &&
apt-get update &&
apt-get install -y terraform
"

docker exec -u root jenkins bash -c "curl -fsSL https://get.docker.com | sh"
```

## 3. Fix Docker socket permissions

Mounting the socket isn't enough on its own — the group that owns it on the host doesn't exist inside the
container by default.

```bash
# Find the socket's group ID on the host
stat -c '%g' /var/run/docker.sock

# Create a matching group inside the Jenkins container and add the jenkins user to it
docker exec -u root jenkins bash -c "groupadd -g <THAT_NUMBER> docker-host 2>/dev/null; usermod -aG docker-host jenkins"

# Restart so the new group membership takes effect
docker restart jenkins
sleep 15
```

Verify:
```bash
docker exec jenkins terraform -version
docker exec jenkins ansible --version
docker exec jenkins docker ps
```

## 4. Create the pipeline job

1. **New Item** → name it → type **Pipeline** → **OK**
2. Under **Pipeline**: Definition → **Pipeline script from SCM** → SCM → **Git**
   - Repository URL: this repo's URL
   - Branch Specifier: `*/main`
   - Script Path: `Jenkinsfile`
3. Save, then **Build Now** to test manually.

## 5. Enable automatic triggering

Job → **Configure** → **Build Triggers** → check **Poll SCM** → schedule:
```
H/2 * * * *
```
Jenkins will now check the repository for new commits every 2 minutes and build automatically — no
manual trigger, and no inbound webhook exposure needed on the server.
