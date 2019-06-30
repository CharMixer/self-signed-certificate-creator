# self-signed-certificate-creator

Configure your certificates in conf.json and add it with -v when running docker

Certificates will be places in /certs wihtin the docker image, which can be added as a volume to retrieve them.

```
docker run -v $(pwd)/certs:/certs -v $(pwd)/conf.json:/conf.json self-signed-certificate-creator
```
