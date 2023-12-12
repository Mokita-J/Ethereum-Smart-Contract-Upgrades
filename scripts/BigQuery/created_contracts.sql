SELECT tx.receipt_contract_address
FROM
  `bigquery-public-data.crypto_ethereum.transactions` AS tx
WHERE
  TIMESTAMP_TRUNC(tx.block_timestamp, DAY) = TIMESTAMP("2023-12-02")
  AND tx.receipt_status = 1
  AND tx.to_address IS NULL;