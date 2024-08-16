



[使用 Jenkins](https://www.jenkins.io/zh/doc/book/using/)



```shell
docker pull jenkinsci/blueocean
```





```shell
docker run -u root --rm -d -p 8080:8080 -v /usr/local/jenkins-data:/var/jenkins_home jenkinsci/blueocean 

```

