
   --Case Study Questions

-- 1. What is the total amount each customer spent at the restaurant?
-- 2. How many days has each customer visited the restaurant?
-- 3. What was the first item from the menu purchased by each customer?
-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?
-- 5. Which item was the most popular for each customer?
-- 6. Which item was purchased first by the customer after they became a member?
-- 7. Which item was purchased just before the customer became a member?
-- 8. What is the total items and amount spent for each member before they became a member?
-- 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?



-- Answers using postgres engine 
SET search_path = dannys_diner;


--Answer 1:  What is the total amount each customer spent at the restaurant?
select customer_id as customer, sum(price) as spent_amount
from sales
join menu
	on sales.product_id = menu.product_id
group by customer_id
order by customer_id asc;

--Answer 2: How many days has each customer visited the restaurant?
select customer_id as customer, count(distinct order_date) as visit_frequency
from sales
group by customer_id
order by customer_id asc;

--Answer 3: What was the first item from the menu purchased by each customer?
select distinct
customer_id as customer, product_name as firstpurchased_menu, order_date as first_orderdate
from sales
	join menu
on sales.product_id = menu.product_id
where order_date = (select min(order_date) from sales where customer_id = sales.customer_id)
order by customer_id;

--Answer 4: What is the most purchased item on the menu and how many times was it purchased by all customers?
select menu.product_name as top_productsales, COUNT(sales.product_id) as TOTAL_PURCHASED
from sales
	join menu
on sales.product_id = menu.product_id 
group by menu.product_name
order by TOTAL_PURCHASED desc
limit 1;

--Answer 5: Which item was the most popular for each customer?
with popular_counting as (
	select customer_id as customer, product_name as mostpopular_menu, count(sales.product_id) as order_count,
		dense_rank() over(partition by sales.customer_id
			order by count(sales.product_id) desc) as ranking
	from sales
		join menu
			on sales.product_id = menu.product_id
	group by sales.customer_id, menu.product_name)

SELECT 
    customer, 
    mostpopular_menu, 
    order_count
FROM popular_counting
WHERE ranking = 1;
 
--Answer 6: Which item was purchased first by the customer after they became a member?
with member_first_order as (
	select  sales.customer_id, 
			menu.product_name, 
			sales.order_date,
			members.join_date,
			row_number() over(partition by sales.customer_id 
				order by sales.order_date) as urutan
	from sales
		join menu
			on sales.product_id = menu.product_id
		join members
			on sales.customer_id = members.customer_id
		where sales.order_date >= members.join_date)
		
select  customer_id, 
		product_name, 
		order_date,
		join_date
from member_first_order
where urutan = 1;
	


--Answer 7: Which item was purchased just before the customer became a member?
with member_first_order as (
	select  sales.customer_id, 
			menu.product_name, 
			sales.order_date as order_beforejoin,
			members.join_date,
			rank() over(partition by sales.customer_id 
				order by sales.order_date desc) as urutan
	from sales
		join menu
			on sales.product_id = menu.product_id
		join members
			on sales.customer_id = members.customer_id
		where sales.order_date < members.join_date)
		
select *
from member_first_order
where urutan = 1;

--Answer 8: What is the total items and amount spent for each member before they became a member?
with member_total_order as (
	select  sales.customer_id, 
			count(sales.product_id) as total_items, 
			sum(menu.price) as totalspent_beforejoin
	from sales 
		join menu
			on sales.product_id = menu.product_id 
		join members
			on sales.customer_id = members.customer_id 
		where sales.order_date < members.join_date
		group by sales.customer_id)

select *
from member_total_order
order by customer_id asc;


--Answer 9: If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
with member_total_points as (
			with member_total_spent as (
			select  sales.customer_id, 
					menu.product_name,
					sum(menu.price) as total_spent
			from sales 
				join menu
					on sales.product_id = menu.product_id 
				group by sales.customer_id,menu.product_name)  
		select *,
				case 
				when product_name = 'sushi' then total_spent * 10 * 2
				else total_spent * 10
				end as total_point
		from member_total_spent
		order by customer_id asc)
--- You can also add ";" after "asc" above, to see pre final point structured table. it is a 2 step process.	
select customer_id, sum(total_point) as final_points
from member_total_points
group by customer_id
order by customer_id asc;
	
--- Alternate answer if only customer already a member is counted.
select 
    sales.customer_id as member_id,
    sum(
        CASE 
            WHEN sales.order_date < members.join_date OR members.join_date IS NULL THEN 0
            WHEN menu.product_name = 'sushi' THEN menu.price * 10 * 2
            ELSE menu.price * 10
        END
    ) AS total_points
from sales
join menu ON sales.product_id = menu.product_id
join members ON sales.customer_id = members.customer_id
group by sales.customer_id
order by sales.customer_id;
	
	
		
--Answer 10: In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?
select 
    sales.customer_id as member_id,
    sum(
        CASE 
             WHEN order_date BETWEEN join_date AND (join_date + interval '7 days') THEN price * 10 * 2
             --it is a dilemma between interval '7days' or '6 days', it depends on inclusive or exclusive terms given e.g join date +7 days or +6 days
         	 WHEN product_name = 'sushi' THEN price * 10 * 2
             WHEN order_date >= join_date AND product_name != 'sushi' THEN price * 10
           END)
    AS total_points
from menu
join sales on menu.product_id = sales.product_id
join members on sales.customer_id = members.customer_id
where sales.order_date <= '2021-01-31' and order_date >= join_date
group by sales.customer_id
order by sales.customer_id;



