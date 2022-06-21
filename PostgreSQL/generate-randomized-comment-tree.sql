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
		random_commentt_in_post.id,
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
			fetch first 1 rows only
		) as random_commentt_in_post on true;
	end loop;
end;
$$;

select c.post_id, c.id, c.parent_commentt_id 
from commentt c where c.post_id  = 652;
--sample result: generated comments and which comment they are a child of 
--|post_id|id    |parent_commentt_id|
--|-------|------|------------------|
--|652    |1,652 |652               |
--|652    |2,652 |652               |
--|652    |3,652 |652               |
--|652    |5,652 |652               |
--|652    |10,652|652               |
--|652    |6,652 |1,652             |
--|652    |11,652|1,652             |
--|652    |9,652 |2,652             |
--|652    |19,652|2,652             |
--|652    |4,652 |3,652             |
--|652    |7,652 |5,652             |
--|652    |8,652 |6,652             |
--|652    |14,652|7,652             |
--|652    |12,652|9,652             |
--|652    |13,652|9,652             |
--|652    |15,652|13,652            |
--|652    |18,652|14,652            |
--|652    |16,652|15,652            |
--|652    |17,652|16,652            |
--|652    |652   |                  |

