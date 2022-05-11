select f10.* into #T
from F10
join S19 on S19.ID=F10.KNOBR
left join F10Tasks on F10Tasks.F10ID=F10.ID
where S19.notes like '%регуляр%' and Status=1 and KWOBR not in (11,14,15) and F10Tasks.id is null 

select ROW_NUMBER() OVER(order by RAND(id*(1000 * DATEPART(mi,GETDATE())+ DATEPART(ms,GETDATE())))) NUM,* into #T2 from S_F10Rajion 
where CountPGUSpec > 0 and id <> 34
order by RAND(id*(1000 * DATEPART(mi,GETDATE())+ DATEPART(ms,GETDATE())))
--select * from #T2

DECLARE @i INT = 1;
declare @n INT = 22
declare @kolObr int = (select count(*) from #T)
declare @kolSpec int = (select sum(countPGuSpec) from S_F10Rajion where CountPGUSpec <> 0)
WHILE @i <= @n
BEGIN
	insert into F10Tasks (F10ID, S_F10Tasks, DateFormed, S20IDFormed, S20NkodFormed, S20IDFor, S20NkodFor)  
	select top ( convert(int, round ((convert(float, @kolObr) * convert(float, (select CountPGUSpec from #T2 where num=@i)) / convert(float, @kolSpec))/10, 1) * 10))
	#T.ID,	D1.status, d1.kol1, d1.kol2, d1.kol3, d1.kol4, d1.kol5
	from #T
	join (select id did1, status, convert(date,GETDATE()) kol1, 1000 kol2, 'Системный администратор' kol3, (select r.s20idfor from Tables.dbo.rajspec r join #T2 on #T2.ID=r.base_number
		where #T2.NUM=@i) kol4,
		(select r.s20nkodfor from Tables.dbo.rajspec r
		join #T2 on #T2.ID=r.base_number
		where #T2.NUM=@i) kol5 from #T) as D1 on D1.did1=#T.id   
	order by RAND((#T.id % 100) * (1000 * DATEPART(mi,GETDATE())+ DATEPART(ms,GETDATE())))
		
	delete from #T
	where id in (select F10ID from F10Tasks where DateFormed=convert(date,GETDATE()) and S20IDFormed=1000)

	SET @i = @i + 1;
END;

insert into F10Tasks (F10ID, S_F10Tasks, DateFormed, S20IDFormed, S20NkodFormed, S20IDFor, S20NkodFor)
select id, D1.status, d1.kol1, d1.kol2, d1.kol3, d1.kol4, d1.kol5
from #T
join (select id did1, status, convert(date,GETDATE()) kol1, 1000 kol2, 'Системный администратор' kol3, 1585 kol4, 'Жиркова Марта Георгиевна' kol5 from #T) as D1 on D1.did1=#T.id