Custom modules for the RDO infrastructure playbooks
===================================================

+---------------+--------------------------------------------------+
| letsencrypt   | For fullchain_ parameter which will land in 2.5  |
+---------------+--------------------------------------------------+
| sensu_check   | For ttl_ parameter which will land in 2.4        |
+---------------+--------------------------------------------------+
| sensu_client  | New sensu_client_ module which will land in 2.4  |
+---------------+--------------------------------------------------+
| sensu_handler | New sensu_handler_ module which will land in 2.4 |
+---------------+--------------------------------------------------+

.. _fullchain: https://github.com/ansible/ansible/commit/f71816c192c0079f51fa93287e55721374bd6ec7#diff-914391d9e58eafc28fbb8234b9e00e17
.. _ttl: https://github.com/ansible/ansible/commit/16073f5b08981ae4521bad9400c2e23e765e280a
.. _sensu_client: https://github.com/ansible/ansible/pull/27529
.. _sensu_handler: https://github.com/ansible/ansible/pull/27680
