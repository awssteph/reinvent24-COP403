with latest_snapshot as (
      select 
            max(date_parse(collection_date, '%Y-%m-%d %T')) as snapshot_last_collection_date
      FROM optimization_data.inventory_snapshot_data
      ),

recent_snapshots as (      
      SELECT
            snapshotid,
            volumeid,
            starttime,
            latest_snapshot.snapshot_last_collection_date,
            ownerid,
            CASE
                  WHEN substr(Description, 1, 22) = 'Created by CreateImage' THEN split_part(Description,' ', 5)
                  WHEN substr(Description, 2, 11) = 'Copied snap' THEN split_part(Description,' ', 9)
                  WHEN substr(Description, 1, 22) = 'Copied for Destination' THEN split_part(Description,' ', 4)
                  ELSE NULL
            END AS snapshot_ami_id
      FROM optimization_data.inventory_snapshot_data
      INNER JOIN latest_snapshot ON latest_snapshot.snapshot_last_collection_date = date_parse(collection_date, '%Y-%m-%d %T')
),
 
snapshot_costs as(
    SELECT
      SPLIT(line_item_resource_id,'/')[2] as snapshot_cur_id,
      SUM(CAST(line_item_unblended_cost AS DECIMAL(16,8))) AS sum_line_item_unblended_cost
    FROM
      "cid_data_export"."cur2"
    WHERE
       product['product_name'] = 'Amazon Elastic Compute Cloud'
      AND line_item_usage_type LIKE '%%EBS%%Snapshot%%'
      AND line_item_line_item_type  =  'Usage'
    GROUP BY
      line_item_resource_id),

latest_ami as (
      select
            max(date_parse(collection_date, '%Y-%m-%d %T')) as ami_last_collection_date
      FROM optimization_data.inventory_ami_data
      ),
recent_amis as (
      SELECT
            imageid,
            description as ami_description,
            latest_ami.ami_last_collection_date
      FROM optimization_data.inventory_ami_data
      -- only see things that overlap
      INNER JOIN latest_ami ON latest_ami.ami_last_collection_date = date_parse(collection_date, '%Y-%m-%d %T')
)

SELECT
      recent_snapshots.*,
      recent_amis.*,
      CASE
            WHEN snapshot_ami_id = imageid THEN 'AMI Available'
            WHEN snapshot_ami_id LIKE 'ami%' THEN 'AMI Removed'
            ELSE 'Not AMI'
      END AS status,
      snapshot_costs.sum_line_item_unblended_cost
FROM recent_snapshots
LEFT JOIN recent_amis ON recent_snapshots.snapshot_ami_id = recent_amis.imageid 
LEFT JOIN snapshot_costs on recent_snapshots.snapshotid = snapshot_costs.snapshot_cur_id 
WHERE snapshot_ami_id is not NULL
order by snapshotid
