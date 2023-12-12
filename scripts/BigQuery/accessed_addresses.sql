SELECT DISTINCT cts.address
FROM
  `bigquery-public-data.crypto_ethereum.transactions` AS tx
INNER JOIN
  `bigquery-public-data.crypto_ethereum.contracts` AS cts
ON tx.to_address = cts.address
WHERE
  TIMESTAMP_TRUNC(tx.block_timestamp, DAY) = TIMESTAMP("2023-12-02")
  AND tx.receipt_status = 1;

