### Update the docker image

```bash
docker build -t scpd-runner:latest .
docker tag scpd-runner:latest dashaun/scpd-runner:latest
docker push dashaun/scpd-runner:latest
```