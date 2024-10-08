with latest_date_snap as (
select distinct date(concat(year,'-',month,'-',day)) as late_date_snap
      FROM "optimization_data"."inventory_snapshot_data"
      order by 1 desc
      limit 1),
latest_date_ami as (
select distinct date(concat(year,'-',month,'-',day)) as late_date_ami
      FROM "optimization_data"."inventory_ami_data"
      order by 1 desc
      limit 1),
snaps as (      
      SELECT snapshotid AS snap_id,
      volumeid as volume,
      volumesize,
      starttime,
      Description AS snapdescription,
      late_date_snap,
      ownerid,
      CASE
      WHEN substr(Description, 1, 22) = 'Created by CreateImage' THEN
      split_part(Description,' ', 5)
      WHEN substr(Description, 2, 11) = 'Copied snap' THEN
      split_part(Description,' ', 9)
      WHEN substr(Description, 1, 22) = 'Copied for Destination' THEN
      split_part(Description,' ', 4)
      ELSE ''
      END AS "snap_ami_id"
  FROM "optimization_data"."inventory_snapshot_data"
  inner join latest_date_snap on latest_date_snap.late_date_snap = date(concat(year,'-',month,'-',day)) 

)
  SELECT *,
  CASE
  WHEN snap_ami_id = imageid THEN
  'AMI Avalible'
  WHEN snap_ami_id LIKE 'ami%' THEN
  'AMI Removed'
  ELSE 'Not AMI'
  END AS status
  from snaps
  left join
  (SELECT imageid,
      name,
      description,
      state,
      rootdevicetype,
      virtualizationtype,late_date_ami

      FROM "optimization_data"."inventory_ami_data"
      inner join latest_date_ami on latest_date_ami.late_date_ami = date(concat(year,'-',month,'-',day)) --inner join only brings back records where both sides match

      ) as ami
      ON snaps.snap_ami_id = ami.imageid 
  
  
  -----

  with latest_snapshot as (
      select 
            max(date_parse(collection_date, '%Y-%m-%d %T')) as snapshot_last_collection_date
      FROM optimization_data.inventory_snapshot_data
      ),

latest_ami as (
      select
            max(date_parse(collection_date, '%Y-%m-%d %T')) as ami_last_collection_date
      FROM optimization_data.inventory_ami_data
      ),

recent_snapshots as (      
      SELECT
            snapshotid,
            volumeid,
            volumesize,
            starttime,
            description AS snapshot_description,
            latest_snapshot.snapshot_last_collection_date,
            ownerid,
            CASE
                  WHEN substr(Description, 1, 22) = 'Created by CreateImage' THEN split_part(Description,' ', 5)
                  WHEN substr(Description, 2, 11) = 'Copied snap' THEN split_part(Description,' ', 9)
                  WHEN substr(Description, 1, 22) = 'Copied for Destination' THEN split_part(Description,' ', 4)
                  ELSE ''
            END AS snapshot_ami_id
      FROM optimization_data.inventory_snapshot_data
      INNER JOIN latest_snapshot ON latest_snapshot.snapshot_last_collection_date = date_parse(collection_date, '%Y-%m-%d %T')
),

recent_amis as (
      SELECT
            imageid,
            name as ami_name,
            description as ami_description,
            state as ami_state,
            rootdevicetype,
            virtualizationtype,
            latest_ami.ami_last_collection_date
      FROM optimization_data.inventory_ami_data
      INNER JOIN latest_ami ON latest_ami.ami_last_collection_date = date_parse(collection_date, '%Y-%m-%d %T')
)

SELECT
      recent_snapshots.*,
      recent_amis.*,
      CASE
            WHEN snapshot_ami_id = imageid THEN 'AMI Avalible'
            WHEN snapshot_ami_id LIKE 'ami%' THEN 'AMI Removed'
            ELSE 'Not AMI'
      END AS status
FROM recent_snapshots
LEFT JOIN recent_amis ON recent_snapshots.snapshot_ami_id = recent_amis.imageid 