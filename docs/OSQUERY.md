```sql
-- get info of containers
SELECT id, name FROM docker_containers;

-- get processes running in "hello-world" container
SELECT
  dc.name container,
  dcp.pid,
  dcp.name process,
  dcp.uid,
  dcp.user
FROM
  docker_container_processes dcp
  JOIN docker_containers dc
  ON dcp.id = dc.id
WHERE dc.name="/hello-world";

-- view which files are open in processes in "hello-world" container (VERIFY!!)
SELECT
  dc.name,
  dcp.pid,
  dcp.name process,
  pof.path
FROM
  process_open_files pof
  JOIN docker_container_processes dcp ON pof.pid = dcp.pid
  JOIN docker_containers dc ON dcp.id = dc.id
WHERE dc.name="/hello-world";

-- view which hosts in the network are is communicating with processes in "hello-world" container (VERIFY!!)
SELECT
  dc.name,
  dcp.pid,
  dcp.name process,
  pos.remote_address,
  pos.protocol
FROM
  process_open_sockets pos
  JOIN docker_container_processes dcp ON pos.pid = dcp.pid
  JOIN docker_containers dc ON dcp.id = dc.id
WHERE dc.name="/hello-world";

```
