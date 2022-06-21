----------------------------------------------------------------------------------------------
--Random string for generating random text in posts and comments
Create or replace function random_name(length integer) returns text as
$$
declare
  chars text[] := '{ Syph , Mateo , Manny , Trevor , Steve , Ash , Michael , Jordan , RJ , Yang , Ada , Lovelace , Einstein , 
Albert , Adolf , Winston , Ann , Alaric , Satoshi , Nakamoto , Gilfoyle , Dinesh , Richard , Hendricks , Russ , Bill , Gates }';
  result text := '';
  i integer := 0;
begin
  if length < 0 then
    raise exception 'Given length cannot be less than 0';
  end if;
  for i in 1..length loop
    result := result || chars[1+random()*(array_length(chars, 1)-1)] || ' ';
  end loop;
  return result;
end;
$$ language plpgsql;

----------------------------------------------------------------------------------------------
--POST
drop table if exists post cascade;

create table post
( 
	id serial constraint post_pk primary key,
	usr_id bigint ,
	title varchar(100),
	body varchar(30000),
	created_date date not null default current_date,
	ups int not null default 1,
	downs int not null default 0,
	del boolean not null default false
);


truncate table post cascade;

do $$
begin
	for i in 1..200 loop
		for j in 1..5 loop
			insert into post(usr_id,title,body,created_date,ups,downs,del) 
			values(
					i,
					random_name(10),
					random_name(15),
					cast(current_date - (random() * (interval '360 days')) + '1 days' as date),
					cast( ((floor(random()*(50-1+1))+1)+random()) as integer ),
					cast( ((floor(random()*(50-1+1))+1)+random()) as integer ),
					false
			);
		end loop;
	end loop;
end;
$$;

----------------------------------------------------------------------------------------------
--COMMENTT
drop table if exists commentt cascade;

create table commentt
( 
	id serial constraint commentt_pk primary key,
	usr_id bigint ,
	post_id bigint ,
	constraint post_fk foreign key(post_id) references post(id),
	parent_commentt_id bigint ,
	constraint parent_commentt_fk foreign key(parent_commentt_id) references commentt(id),
	body varchar(20000),
	created_date date not null default current_date,
	ups int not null default 1,
	downs int not null default 0,
	del boolean not null default false
);

truncate table commentt cascade;

do $$
begin
	for j in 1..20 loop
		insert into commentt(usr_id,post_id,parent_commentt_id,body,created_date,ups,downs,del) 
		select p.usr_id,
		p.id,
		case when (cast( ((floor(random()*(3-1+1))+1)+random()) as integer )) = 1 
			then null 
			else random_commentt_in_post.id
		end, --1 out of 4 generated comments have a null parent id, these are 'direct' comments to a post
		random_name(9),
		cast(current_date - (random() * (interval '360 days')) + '1 days' as date),
		cast( ((floor(random()*(50-1+1))+1)+random()) as integer ),
		cast( ((floor(random()*(50-1+1))+1)+random()) as integer ),
		false
		from post p
		left join (
			select count(c.post_id) as commentts_count, c.post_id  from commentt c 
			group by c.post_id
		) as commentts_count_per_post on commentts_count_per_post.post_id = p.id 
		left join lateral ( 
			select c.id from commentt c where c.post_id = p.id 
			offset floor(random() * commentts_count_per_post.commentts_count)
			fetch first 1 rows only --select a random comment from the existing comments under the post
		) as random_commentt_in_post on true;
	end loop;
end;
$$;

select c.post_id, c.id, c.parent_commentt_id 
from commentt c where c.post_id  = 1;
--sample result: generated comments under post with id 1 and which comment they are a child of 
--|post_id|id    |parent_commentt_id|
--|-------|------|------------------|
--|1      |1     |                  |
--|1      |1,001 |1                 |
--|1      |2,001 |1                 |
--|1      |3,001 |2,001             |
--|1      |4,001 |1                 |
--|1      |5,001 |1                 |
--|1      |6,001 |1,001             |
--|1      |7,001 |1                 |
--|1      |8,001 |                  |
--|1      |9,001 |3,001             |
--|1      |10,001|2,001             |
--|1      |11,001|4,001             |
--|1      |12,001|                  |
--|1      |13,001|1                 |
--|1      |14,001|8,001             |
--|1      |15,001|14,001            |
--|1      |16,001|5,001             |
--|1      |17,001|14,001            |
--|1      |18,001|15,001            |
--|1      |19,001|1,001             |

