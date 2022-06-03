CREATE TABLE sales (
  "customer_id" VARCHAR(1),
  "order_date" DATE,
  "product_id" INTEGER
);

INSERT INTO sales
  ("customer_id", "order_date", "product_id")
VALUES
  ('A', '2021-01-01', '1'),
  ('A', '2021-01-01', '2'),
  ('A', '2021-01-07', '2'),
  ('A', '2021-01-10', '3'),
  ('A', '2021-01-11', '3'),
  ('A', '2021-01-11', '3'),
  ('B', '2021-01-01', '2'),
  ('B', '2021-01-02', '2'),
  ('B', '2021-01-04', '1'),
  ('B', '2021-01-11', '1'),
  ('B', '2021-01-16', '3'),
  ('B', '2021-02-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-07', '3');
 

CREATE TABLE menu (
  "product_id" INTEGER,
  "product_name" VARCHAR(5),
  "price" INTEGER
);

INSERT INTO menu
  ("product_id", "product_name", "price")
VALUES
  ('1', 'sushi', '10'),
  ('2', 'curry', '15'),
  ('3', 'ramen', '12');
  

CREATE TABLE members (
  "customer_id" VARCHAR(1),
  "join_date" DATE
);

INSERT INTO members
  ("customer_id", "join_date")
VALUES
  ('A', '2021-01-07'),
  ('B', '2021-01-09');


select s.customer_id, sum(price) as "Total Sum"
from menu as m
join sales as s
on m.product_id = s.product_id
group by customer_id

select customer_id, count(distinct order_date) as "Date"
from sales 
group by customer_id

select distinct(customer_id), product_name 
from sales s 
join menu m
on m.product_id = s.product_id
where s.order_date = any (select min(order_date) from sales group by customer_id)

select top 1 product_name, count(order_date) as cnt
from sales s
join menu m
on m.product_id = s.product_id
group by product_name
order by cnt desc

select s.customer_id, count(m.product_name)
from sales s 
join menu m
on m.product_id = s.product_id

with rank as(
select s.customer_ID, m.product_name, count(s.product_id) as Count,
Dense_rank() over (partition by s.customer_id order by count(s.product_id) DESC) as Rank
from menu m
join sales s
on m.product_id = s.product_id
group by s.customer_id, m.product_name, s.product_id
)
select customer_id, product_name, Count
from rank
where rank = 1


with ranks as(
select s.customer_id, m.product_name, dense_rank() over (partition by s.customer_id order by s.order_date) as ranks
from sales s
join menu m 
on s.product_id = m.product_id
join members as mem
on mem.customer_id = s.customer_id
where s.order_date >= mem.join_date
)
select * 
from ranks
where ranks = 1


with ranks as(
select s.customer_id, m.product_name, dense_rank() over (partition by s.customer_id order by (s.order_date) desc) as ranks
from sales s
join menu m
on s.product_id = m.product_id
join members as mem
on mem.customer_id = s.customer_id
where s.order_date<mem.join_date 
)
select customer_id, product_name
from ranks
where ranks = 1

select s.customer_id, count(s.product_id) as count, sum(m.price) as price
from sales s
join menu m
on s.product_id = m.product_id
join members mem
on s.customer_id = mem.customer_id
where s.order_date<mem.join_date
group by s.customer_id

with points as
(
select *, 
case
when product_id = 1 then price*20
when product_id = 2 then price*10
end as points
from menu
)
select s.customer_id, sum(p.points) as points
from sales s
join points p
on s.product_id = p.product_id
group by s.customer_id

with dates as
(
select *, dateadd(day, 6, join_date) as week_day, eomonth('2021-01-31') as last_date
from members
)
select s.customer_id, 
sum(case
when m.product_id = 1 then m.price*20
when s.order_date between d.join_date and d.week_day then m.price*20
else m.price*10
end
) as points
from dates d
join sales s
on d.customer_id = s.customer_id 
join menu m
on m.product_id = s.product_id
where s.order_date < d.last_date
group by s.customer_id

select s.customer_id, s.order_date, m.product_name, m.price, (case
when mem.join_date < s.order_date then 'N'
else 'Y'
end) as member
from sales s
join menu m
on s.product_id = m.product_id
join members mem
on s.customer_id = mem.customer_id

with ranks as 
(
select s.customer_id, s.order_date, m.product_name, m.price,(case
when s.order_date < mem.join_date then 'N'
when s.order_date >= mem.join_date then 'Y'
end) as member 
from sales as s
join menu as m
on s.product_id = m.product_id
join members as mem
on s.customer_id = mem.customer_id
)
select *, case
when member = 'N' then NULL
else rank() over(partition by customer_id, member order by order_date) end as rank
from ranks
