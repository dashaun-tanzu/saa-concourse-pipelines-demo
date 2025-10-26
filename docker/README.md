### Update the docker image

```bash
echo $DOCKER_PASS | docker login -u $DOCKER_USER --password-stdin
docker build -t scpd-runner:latest .
docker tag scpd-runner:latest dashaun/scpd-runner:latest
docker push dashaun/scpd-runner:latest
```