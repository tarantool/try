# Try Tarantool

- Build docker container
  ```bash
  docker build -t try-tarantool .
  ```

- Run docker container with Tarantool
  ```bash
  docker run --rm -it -p 8081:8081 try-tarantool
  ```

- Visit [localhst:8081](localhost:8081) in your browser and 
  check out the tutorial to get started with Tarantool

  Use default credentials to sign in:  
  login: `admin`  
  password:  `password`
