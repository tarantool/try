# [Tutorial] Developers

Today you are going to solve a high-performance challenge for TikTok with Tarantool.

You will implement a counter of likes for videos. First, you will create base tables and search indexes. Then you will define the HTTP API for mobile clients. And most importantly, you will make sure that the counter doesn't lose likes under high load.

If you accidentally do something wrong while following the instructions, there is a magic button that helps you reset all the changes.

It is called **Reset Configuration**. You can find it in the upper right corner.

**Everything you need to know to get started:**

A Tarantool cluster has two service roles: Router and Storage.

- Storage is used to store the data
- Router is an intermediary between clients and storages. It accepts a client's request, takes data from the proper storage, and returns it to the client.

## Configuring a Cluster

On the Cluster tab, you can see that you have five unconfigured instances. For a start, create a router and a storage.

...

Enable sharding.

...

## Creating a Data Schema [2 minutes]

Get started with a data schema – go to the Schema tab on the left. On this tab, you can create a new data schema for the entire cluster, edit the current schema, validate its correctness and apply it to the whole cluster.

Create the necessary tables. In Tarantool, they are called spaces.

You will need to store:

- users
- videos and their descriptions, with a pre-calculated number of likes
- **actual likes**

The data schema will look like this:

- [expand] Tiktok DDL

    ```yaml
    spaces:
      users:
        engine: memtx
        is_local: false
        temporary: false
        sharding_key: 
        - "user_id"
        format:
        - {name: bucket_id, type: unsigned, is_nullable: false}
        - {name: user_id, type: uuid, is_nullable: false}
        - {name: fullname, type: string,  is_nullable: false}
        indexes:
        - name: user_id
          unique: true
          parts: [{path: user_id, type: uuid, is_nullable: false}]
          type: HASH
        - name: bucket_id
          unique: false
          parts: [{path: bucket_id, type: unsigned, is_nullable: false}]
          type: TREE

      videos:
        engine: memtx
        is_local: false
        temporary: false
        sharding_key: 
        - "video_id"
        format:
        - {name: bucket_id, type: unsigned, is_nullable: false}
        - {name: video_id, type: uuid, is_nullable: false}
        - {name: description, type: string, is_nullable: true}
        - {name: likes, type: unsigned, is_nullable: false}
        indexes:
        - name: video_id
          unique: true
          parts: [{path: video_id, type: uuid, is_nullable: false}]
          type: HASH
        - name: bucket_id
          unique: false
          parts: [{path: bucket_id, type: unsigned, is_nullable: false}]
          type: TREE

      likes:
        engine: memtx
        is_local: false
        temporary: false
        sharding_key: 
        - "video_id"
        format:
        - {name: bucket_id, type: unsigned, is_nullable: false}
        - {name: like_id, type: uuid, is_nullable: false }
        - {name: user_id,  type: uuid, is_nullable: false}
        - {name: video_id, type: uuid, is_nullable: false}
        - {name: timestamp, type: string,   is_nullable: true}
        indexes:
        - name: like_id
          unique: true
          parts: [{path: like_id, type: uuid, is_nullable: false}]
          type: HASH
        - name: bucket_id
          unique: false
          parts: [{path: bucket_id, type: unsigned, is_nullable: false}]
          type: TREE
    ```

It's simple. Let's take a closer look at the essential points.

Tarantool has two built-in storage engines: memtx and vinyl. Memtx stores all data in RAM while asynchronously writing to disk so that nothing is lost.

Vinyl is a standard on-disk storage engine optimized for write-intensive scenarios.

In this tutorial, you have a large number of both reads and writes. That's why you will use memtx.

You've created three spaces (tables) in memtx, and for each space, you've created the necessary indexes.

There are two of them for each space:

- The first index is a primary key. It is required for reading and writing data.
- The second one is the index on the `bucket_id` field. This is a special field used in sharding.

**Important:** The name `bucket_id` is reserved. If you choose a different name, sharding will not work for that space. If you don't use sharding in the project, you can remove the second index.

Tarantool uses `sharding_key` to figure out which field to use for sharding. <0>sharding_key</0> refers to the field in the space that is used for sharding. Tarantool takes the hash from this field during insertion, calculates the bucket number, and selects the right storage for writing data.

Buckets may be repeated, and each storage stores a certain range of buckets.

More interesting facts:

- The `parts` field in the index definition can contain several fields in order to build a composite (multi-part) index. You won't need it in this tutorial.
- Tarantool does not support foreign keys, so you have to check manually that `video_id` and `user_id` exist in the `likes` space.

**Great! Let's apply the schema** to the whole cluster. Go to the Schema tab in the cluster, copy the schema into the field, and click Apply. Done. The same data schema gets applied to all the nodes.

## Writing Data [5 minutes]

You are going to write data to the Tarantool cluster using the CRUD module. This module defines which shard to read from and which shard to write to, and does it for you.

Important: all cluster operations must be performed only on the router and using the CRUD module.

Plug the CRUD module and declare three procedures:

- creating a user
- adding a video
- liking a video

```lua
local cartridge = require('cartridge')
local crud = require('crud')
local uuid = require('uuid')
local json = require('json')

function add_user(request)
    local fullname = request:post_param("fullname")
    local result, err = crud.insert_object('users', { user_id = uuid.new(), fullname = fullname })
    if err ~= nil then
        return { body = json.encode({status = "Error!", error = err}), status = 500 }
    end

    return { body = json.encode({status = "Success!", result = result}), status = 200 }
end

function add_video(request)
    local description = request:post_param("description")
    local result, err = crud.insert_object('videos', { video_id = uuid.new(), description = description, likes = 0 })
    if err ~= nil then
        return { body = json.encode({status = "Error!", error = err}), status = 500 }
    end

    return { body = json.encode({status = "Success!", result = result}), status = 200 }
end

function like_video(request)
    local video_id = request:post_param("video_id")
    local user_id = request:post_param("user_id")

    local result, err = crud.update('videos', uuid.fromstr(video_id), {{'+', 'likes', 1}})
    if err ~= nil then
        return { body = json.encode({status = "Error!", error = err}), status = 500 }
    end

    result, err = crud.insert_object('likes', { like_id = uuid.new(),
                                                video_id = uuid.fromstr(video_id),
                                                user_id = uuid.fromstr(user_id)})
    if err ~= nil then
        return { body = json.encode({status = "Error!", error = err}), status = 500 }
    end

    return { body = json.encode({status = "Success!", result = result}), status = 200 }
end
```

Note that there can be several routers in the cluster, and requests for likes of the same video can come to the storage at the same time.

Since the `update` operation in Tarantool ensures that no data is lost during the update, you don't have to worry about multiple clients connecting at the same time.

For simplicity, `update` and `insert_object` operations in the `like_video` method are not in a transaction. To learn how transactions work, read the [Transactions section of Tarantool documentation](https://www.tarantool.io/en/doc/latest/book/box/atomic/).

## Setting up HTTP API [2 minutes]

Clients will connect to the Tarantool cluster via the HTTP protocol. The cluster already has its own built-in HTTP server. Configure the paths:

```lua
local function init(opts)
    local httpd = cartridge.service_get('httpd')
    httpd:route({path = '/like', method = 'POST'}, like_video)
    httpd:route({path = '/add_user', method = 'POST'}, add_user)
    httpd:route({path = '/add_video', method = 'POST'}, add_video)

    return true
end
```

Done! Now send test queries from the console:

```bash
curl -X POST --data "fullname=Taran Tool" try-cartridge.tarantool.io:19528/add_user
curl -X POST --data "description=My first tiktok" try-cartridge.tarantool.io:19528/add_video
curl -X POST --data "video_id=ab45321d-8f79-49ec-a921-c2896c4a3eba,user_id=bb45321d-9f79-49ec-a921-c2896c4a3eba" try-cartridge.tarantool.io:19528/like_video
```

It goes something like this:

![Тестовые запросы в консоли](images/console.png)

## Looking at the Data [1 minute]

Go to the Space-Explorer tab and see all the cluster nodes. Since you have one storage and one router so far, the data is stored on a single node.

Go to the `s1-master` node, click Connect and select the necessary space.

Check that everything is in place and move on.

![Space Explorer, host list](images/hosts.png)

![Space Explorer, viewing likes](images/likes.png)

## Scaling the Cluster [1 minute]

Create a second shard. Go to the Cluster tab, select `s2-master`, and click Configure. Select the roles as shown in the picture:

![Space Explorer, host s1-master](images/s1-master.png)

![Space Explorer, configuring new shard](images/configuring-server.png)

Click on the roles and create a shard (replicaset).

Add the `s1-replica` and `s2-replica` nodes as replicas to the first and the second shard respectively.

## Checking Sharding [1 minute]

Now you have two shards, or two logical nodes that receive data. The router determines where it sends the data. By default, it uses the hash function for the `sharding_key` field specified in DDL.

To enable a new shard, you have to set its weight to one. Go back to the Cluster tab, open the `s2-master` settings, set Replica set weight to "1" and apply.

Something has already happened. Go to space-explorer and open the `s2-master` node. It turns out that some of the data from the first shard has already migrated here! The scaling is done automatically.

Now try to add more data to the cluster using the HTTP API. You can check and make sure that the new data is also evenly distributed among the two shards.

## Disconnecting a Shard for a While [1 minute]

In the `s1-master` settings, set Replica set weight to "0" and apply. Wait for a few seconds, then go to space-explorer and look at the data in `s2-master` – all the data has been migrated to the remaining shard automatically.

Now you can safely disconnect the first shard to perform maintenance.

---

## What's next?

Deploy the environment locally and continue exploring Tarantool.

Four components are used in the example:

- Tarantool — an in-memory database
- Tarantool Cartridge – the cluster UI and framework for distributed applications development based on Tarantool
- [DDL](https://github.com/tarantool/ddl) module — for clusterwide DDL schema application
- [CRUD](https://github.com/tarantool/crud) module —for CRUD (create, read, update, delete) operations in cluster



### Install locally:

#### For Linux/macOS users

- Install Tarantool [from the Download page](https://tarantool.io/ru/download)
- Install the `cartridge-cli` utility using your package manager

```bash
sudo yum install cartridge-cli
```

```bash
brew install cartridge-cli
```

Learn more about installing the `cartridge-cli` utility [here](https://github.com/tarantool/cartridge-cli).

-   Clone the repository [https://github.com/tarantool/try-tarantool-example](https://github.com/tarantool/try-tarantool-example).

    This repository is ready for use.

-   In the folder with the cloned example, run:

    ```bash
    cartridge build
    cartridge start
    ```

    This is necessary to install dependencies and start the project. Here, the dependencies are Tarantool Cartridge, DDL, and CRUD.

Done! You can see the Tarantool Cartridge UI at [http://localhost:8081](http://localhost:8081).

#### For Windows users

Use a Docker container with СentOS 8 or WSL and follow the Linux installation instructions.

### See also

- [Study the Tarantool Cartridge documentation](https://www.tarantool.io/ru/doc/latest/book/cartridge/) and create your own distributed application
- Explore the repository [tarantool/examples](https://github.com/tarantool/examples) on Github with ready-made examples on Tarantool Cartridge: cache, MySQL replicator, and others.
- README of the [DDL](https://github.com/tarantool/ddl) module to create your own data schema
- README of the [CRUD](https://github.com/tarantool/crud) module to learn more about API and create your own cluster queries