--
-- Shows SQL Plan Directives for db object
-- Usage: SQL> @spd_obj ""              JPS_ATTRS    USABLE
--                      ^[object_owner] ^object_name ^state
--

set feedback on 0 heading on timi off pages 200 lines 500 echo off  VERIFY OFF

col INT_STATE for a16
col REDUNDANT for a9
col OWNER for a30
col TABLE_LIST  for a100
col COLUMN_LIST for a100
col EQ_PRED_ONLY for a13
col SIMPLE_COL_PRED_ONLY for a21
col IND_ACCESS_BY_JOIN_PRED for a24
col FILTER_ON_JOIN_OBJ for a19
col created for a19
col last_modified for a19
col last_used for a19

with d as (
select --+ rule
 to_char(d.f_id, '999999999999999999999') as finding_id,
 to_char(d.dir_id, '999999999999999999999') as directive_id,
 d.type,
 d.enabled,
 d.internal_state as int_state,
 case when d.internal_state = 'HAS_STATS' or d.redundant = 'YES' then 'SUPERSEDED'
      when d.internal_state in ('NEW', 'MISSING_STATS', 'PERMANENT') then 'USABLE'
      else 'UNKNOWN' end as STATE,
-- d.auto_drop,
-- f.type,
 f.reason,
 f.tab_cnt,
 to_char(d.created,'dd.mm.yy hh24:mi:ss')       as created,
 to_char(d.last_modified,'dd.mm.yy hh24:mi:ss') as last_modified,
 to_char(d.last_used,'dd.mm.yy hh24:mi:ss')     as last_used,
 d.redundant,
-- 'TABLE' as object_type,
 u.name  as owner,
 o.name  as table_name,
 c.name  as column_name,
 extractvalue(fo.notes, '/obj_note/equality_predicates_only')        as eq_pred_only,
 extractvalue(fo.notes, '/obj_note/simple_column_predicates_only')   as simple_col_pred_only,
 extractvalue(fo.notes, '/obj_note/index_access_by_join_predicates') as ind_access_by_join_pred,
 extractvalue(fo.notes, '/obj_note/filter_on_joining_object')        as filter_on_join_obj
  from sys."_BASE_OPT_DIRECTIVE" d
  join sys."_BASE_OPT_FINDING" f on f.f_id = d.f_id
  join sys."_BASE_OPT_FINDING_OBJ" fo on f.f_id = fo.f_id
  join (select obj#, owner#, name from sys.obj$
        union all
        select object_id obj#, 0 owner#, name from  v$fixed_table) o on fo.f_obj# = o.obj#
  join sys.user$ u on o.owner# = u.user#
  left join sys."_BASE_OPT_FINDING_OBJ_COL" ft on f.f_id = ft.f_id and fo.f_obj# = ft.f_obj#
  left join (select obj#, intcol#, name from sys.col$
             union all
             select kqfcotob obj#, kqfcocno intcol#, kqfconam name
             from sys.x$kqfco) c on o.obj# = c.obj# and ft.intcol# = c.intcol#
 where d.dir_id in --(8395296349203607205)
                   (select dir_id
                          from sys."_BASE_OPT_DIRECTIVE"       d,
                               sys."_BASE_OPT_FINDING_OBJ_COL" ft
                         where ft.f_obj# in
                               (select object_id name
                                  from dba_objects
                                 where owner = nvl(upper('&1'),owner) and object_name = upper('&2'))
                           and d.f_id = ft.f_id))
select 
     --finding_id,
       directive_id,
       type as SPD_TYPE,
       enabled,
       int_state,
       STATE,
       -- auto_drop,
       -- type,
       reason,
       tab_cnt,
       redundant,
--       listagg(owner || '.' || table_name, ', ') within group(order by table_name, column_name) as table_list,
       substr(regexp_replace(listagg(owner || '.' || table_name, ',') within group(order by table_name),'([^,]+)(,\1)+', '\1'),1,100) as table_list,
       substr(listagg(column_name, ', ') within group(order by column_name),1,100) as column_list,
       max(eq_pred_only) as eq_pred_only,
       max(simple_col_pred_only) as simple_col_pred_only,
       max(ind_access_by_join_pred) as ind_access_by_join_pred,
       max(filter_on_join_obj) as filter_on_join_obj,
       created,
       last_modified,
       last_used
  from d
 where state = nvl('&&3',state)
 group by 
        --finding_id,
          directive_id,
          type,
          enabled,
          int_state,
          STATE,
          -- auto_drop,
          -- type,
          reason,
          tab_cnt,
          created,
          last_modified,
          last_used,
          redundant
 order by directive_id desc
/

--unset &1
--unset &2
--unset &&3

set feedback on VERIFY ON timi on