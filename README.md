Give execution permission

```sh
chmod +x composer
```

Build docker image

```sh
./composer --build
```

Kill & remove docker containers

```sh
./composer --clean
```

Run docker

```sh
# Implies --clean and --build options
./composer --run
```
