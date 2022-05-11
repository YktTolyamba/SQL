--------------------------------------рабочий скрипт--------------------------------------------


--создание таблицы с порци€ми (один раз в начале мес€ца)
drop table tables.dbo.jku_por

select k.DB_ID, k.ulus, k.kol, k.kol/15 por 
into tables.dbo.jku_por
from (
	select tables.dbo.jkustar2.DB_ID, tables.dbo.jkustar2.ulus, count(tables.dbo.jkustar2.id) kol from tables.dbo.jkustar2
	group by tables.dbo.jkustar2.DB_ID, ulus) k
order by DB_ID

--0.
drop table #T


--1. загрузка всех id во временную таблицу
select distinct f2.id, f6.DB_ID into #T 
from f2 with (nolock)
inner join f6 with (nolock) on (f2.id = f6.f2_id)
where  (cast(f2.id as bigint)>0 and ((f2.psy is null and f2.datpsy is null)))
and ((("f6"."kod"=22010000000000 or "f6"."kod"=22020000000000 or "f6"."kod"=22070000000000)) 
and ( (f6.k_gsp = 2 and f6.id in (SELECT DISTINCT F6_ID FROM F6IZM with(nolock) WHERE F6.ID=F6IZM.F6_ID and f6izm.state=2 
AND ISNULL(F6IZM.DAT_START, '30.04.2022')<='30.04.2022' AND ISNULL(F6IZM.DAT_END,'01.04.2022')>='01.04.2022' 
AND NOT EXISTS (SELECT F6PREKR.ID FROM F6PREKR with(nolock) WHERE F6IZM_ID=F6IZM.ID AND ISNULL(DATOTK,'01.04.2022')<='01.04.2022' 
AND ISNULL(SRP,'30.04.2022')>='30.04.2022'))) 
or (f6.k_gsp = 9 and f6.id in (SELECT DISTINCT F6_ID FROM F6IZM with(nolock) 
WHERE F6.ID=F6IZM.F6_ID AND ISNULL(F6IZM.DAT_START,'30.04.2022')<='30.04.2022' AND ISNULL(F6IZM.DAT_END,'01.04.2022')>='01.04.2022' AND NOT EXISTS 
(SELECT F6PREKR.ID FROM F6PREKR with(nolock) WHERE F6IZM_ID=F6IZM.ID AND ISNULL(DATOTK,'01.04.2022')<='01.04.2022' AND ISNULL(SRP,'30.04.2022')>='30.04.2022'))) 
or (f6.k_gsp = 3 and f6.id in (SELECT A.DECL_ID FROM F_PENSASSIGN A with(nolock) WHERE F6.ID=A.DECL_ID AND ISNULL(A.DATE_START,'30.04.2022')<='30.04.2022' 
AND ISNULL(A.DATE_END,'01.04.2022')>='01.04.2022' AND NOT EXISTS (SELECT F6PREKR.ID FROM F6PREKR with(nolock) WHERE ASSIGN_ID=A.ID 
AND ISNULL(DATOTK,'01.04.2022')<='01.04.2022' AND ISNULL(SRP,'30.04.2022')>='30.04.2022'))) 
or (f6.k_gsp not in (3,9,2) and f6.id in (((select f6.id from f6 with(nolock) 
where not (isnull(f6.DATOTK, DATEADD(dd,1,'01.04.2022')) <= '01.04.2022' and isnull(f6.SRP, DATEADD(dd,-1,'30.04.2022'))>='30.04.2022') 
and isnull(f6.datwp,'30.04.2022') <= '30.04.2022' and isnull(f6.srdz,'01.04.2022') >= '01.04.2022' 
and not exists(select f6prekr.id from f6prekr with (nolock) where f6.id=f6prekr.f6_id and ISNULL(f6prekr.datotk,'01.04.2022') <= '01.04.2022' 
and isnull(f6prekr.datvost,'30.04.2022') >= '30.04.2022' ))))) ))
order by f2.ID

select * from #T
order by id


--2. группировка общего кол-ва по улусам, создание jkustar2
drop table #T2
drop table tables.dbo.jkustar2

select distinct #T.ID, max(db_id) db_id into #T2 from #T
group by #T.id
order by #T.id

select DB_ID, reg.NKOD ulus, #T2.id into tables.dbo.jkustar2 from #T2
join DATABASEINFO on DATABASEINFO.id=#T2.DB_ID
join REG on reg.id=DATABASEINFO.reg_id
group by #T2.db_id, reg.NKOD, #T2.id
order by #T2.db_id, #T2.id

select * from tables.dbo.jkustar2
order by db_id, id


--3. удаление ранее отправленных из таблицы tables.dbo.jkustar2
delete from tables.dbo.jkustar2
where id in (select id from tables.dbo.jku)


--4. формирование порций дл€ выгрузки, создание jkustar3
drop table tables.dbo.jkustar3

CREATE TABLE tables.dbo.jkustar3 (
	id int,
	db_id int,
	ulus varchar(255)
);
DECLARE @i INT = 2;
declare @n INT = 37
WHILE @i < @n
BEGIN
   insert into tables.dbo.jkustar3
   select top ( select por from tables.dbo.jku_por where DB_ID=@i ) ID, db_id, ulus 
   from tables.dbo.jkustar2
   where db_ID=@i
   order by id
   SET @i = @i + 1;
END;

select * from tables.dbo.jkustar3
order by db_id


--4.5 сохранение отправленных людей в таблицу jku
insert into tables.dbo.jku
select *, convert(date,GETDATE()) date_export from tables.dbo.jkustar3