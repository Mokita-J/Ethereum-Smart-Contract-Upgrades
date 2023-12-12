SELECT
 cts.address
FROM
 `bigquery-public-data.crypto_ethereum.logs` AS logs
INNER JOIN
 `bigquery-public-data.crypto_ethereum.contracts` AS cts
ON
 logs.address=cts.address
WHERE
 TIMESTAMP_TRUNC(logs.block_timestamp, DAY) = TIMESTAMP("2023-12-02")
 AND ARRAY_LENGTH(logs.topics)<>0
 AND logs.topics[
OFFSET
 (0)] IN ('0xd32d24edea94f55e932d9a008afc425a8561462d1b1f57bc6e508e9a6b9509e1',
          '0x8faa70878671ccd212d20771b795c50af8fd3ff6cf27f4bde57e5d4de0aeb673',
          '0xbc7cd75a20ee27fd9adebab32041f755214dbc6bffa90cc0225b39da2e5c2d3b')