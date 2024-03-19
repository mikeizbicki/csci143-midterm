/* PROBLEM 1:
 *
 * The Office of Foreign Assets Control (OFAC) is the portion of the US government that enforces international sanctions.
 * OFAC is conducting an investigation of the Pagila company to see if you are complying with sanctions against North Korea.
 * Current sanctions limit the amount of money that can be transferred into or out of North Korea to $5000 per year.
 * (You don't have to read the official sanctions documents, but they're available online at <https://home.treasury.gov/policy-issues/financial-sanctions/sanctions-programs-and-country-information/north-korea-sanctions>.)
 * You have been assigned to assist the OFAC auditors.
 *
 * Write a SQL query that:
 * Computes the total revenue from customers in North Korea.
 *
 * NOTE:
 * All payments in the pagila database occurred in 2022,
 * so there is no need to do a breakdown of revenue per year.
 */

SELECT
    sum(amount) as amount
FROM customer
JOIN address USING (address_id)
JOIN city USING (city_id)
JOIN country USING (country_id)
JOIN payment USING (customer_id)
WHERE country = 'North Korea';

-- GRADING:
-- most people got full credit;
-- if you didn't, then there's notes in sakai about why


/* PROBLEM 2:
 *
 * Management wants to hire a family-friendly actor to do a commercial,
 * and so they want to know which family-friendly actors generate the most revenue.
 *
 * Write a SQL query that:
 * Lists the first and last names of all actors who have appeared in movies in the "Family" category,
 * but that have never appeared in movies in the "Horror" category.
 * For each actor, you should also list the total amount that customers have paid to rent films that the actor has been in.
 * Order the results so that actors generating the most revenue are at the top.
 */


SELECT
    first_name,
    last_name,
    actor_id,
    SUM(amount) AS revenue
FROM payment
JOIN rental USING (rental_id)
JOIN inventory USING (inventory_id)
JOIN film USING (film_id)
JOIN film_actor USING (film_id)
JOIN actor USING (actor_id)
WHERE actor_id NOT IN (
    SELECT actor_id
    FROM actor
    JOIN film_actor USING (actor_id)
    JOIN film USING (film_id)
    JOIN film_category USING (film_id)
    JOIN category USING (category_id)
    WHERE name='Horror'
)
AND actor_id IN (
    SELECT actor_id
    FROM actor
    JOIN film_actor USING (actor_id)
    JOIN film USING (film_id)
    JOIN film_category USING (film_id)
    JOIN category USING (category_id)
    WHERE name='Family'
)
GROUP BY actor_id, first_name, last_name
ORDER BY revenue DESC;

-- GRADING
-- 4 points for the right actors (hw question, so most people got this)
-- 4 points for the right revenue (lots of mistakes here)

-- Example:
-- revenue too low because of including the category in the outer list of joins;
-- this causes the sum to only include films from the specified category instead of all films
SELECT
    first_name,
    last_name,
    actor_id,
    sum(amount) as revenue
FROM actor
JOIN film_actor USING (actor_id)
JOIN film USING (film_id)
JOIN film_category USING (film_id)
JOIN category USING (category_id)
JOIN inventory USING (film_id)
JOIN rental USING (inventory_id)
JOIN payment USING (rental_id)
WHERE
    category.name IN ('Family')
AND actor_id NOT IN (
    SELECT DISTINCT
        actor_id
    FROM film_actor
    JOIN film USING (film_id)
    JOIN film_category USING (film_id)
    JOIN category USING (category_id)
    WHERE
        category.name IN ('Horror')
    )
GROUP BY actor_id
ORDER BY revenue DESC;

-- Example:
-- revenue too high because the wrong column is used in the JOIN USING clause
SELECT first_name, last_name, sum(amount) as actor_revenue
FROM actor
JOIN film_actor USING (actor_id)
JOIN film USING (film_id)
JOIN inventory USING (film_id)
JOIN rental USING (inventory_id)
JOIN payment USING (customer_id) -- wrong column here!
JOIN (
        SELECT DISTINCT actor_id
        FROM film_actor
        JOIN film USING (film_id)
        JOIN film_category USING (film_id)
        JOIN category USING (category_id)
        WHERE name = 'Family'
) family USING (actor_id)
WHERE actor_id NOT IN (
        SELECT actor_id
        FROM film_actor
        JOIN film USING (film_id)
        JOIN film_category USING (film_id)
        JOIN category USING (category_id)
        WHERE name = 'Horror'
)
GROUP BY first_name, last_name
ORDER BY actor_revenue DESC;


/* PROBLEM 3:
 *
 * You love the acting in AGENT TRUMAN, but you hate the actor RUSSELL BACALL.
 *
 * Write a SQL query that lists all of the actors who starred in AGENT TRUMAN
 * but have never co-starred with RUSSEL BACALL in any movie.
 */

SELECT first_name, last_name
FROM actor
WHERE actor_id IN (

    -- actors in AGENT TRUMAN
    SELECT
        fa1.actor_id
    FROM film_actor fa1
    JOIN film_actor fa2 ON fa2.actor_id = fa1.actor_id
    JOIN film f2 ON f2.film_id = fa2.film_id
    WHERE f2.title = 'AGENT TRUMAN'

    EXCEPT

    -- actors who have co-starred with RUSSEL BACALL
    SELECT 
        a1.actor_id
    FROM actor a1
    JOIN film_actor fa1 ON fa1.actor_id=a1.actor_id
    JOIN film_actor fa2 ON fa1.film_id=fa2.film_id
    JOIN actor a2 ON fa2.actor_id=a2.actor_id
    WHERE a2.first_name = 'RUSSELL'
      AND a2.last_name = 'BACALL'
);

-- GRADING:

-- (-2) Common mistake was to hard-code Russel Bacall's actor_id
SELECT first_name, last_name
FROM actor
WHERE actor_id IN (

    -- actors in AGENT TRUMAN
    SELECT
        fa1.actor_id
    FROM film_actor fa1
    JOIN film_actor fa2 ON fa2.actor_id = fa1.actor_id
    JOIN film f2 ON f2.film_id = fa2.film_id
    WHERE f2.title = 'AGENT TRUMAN'

    EXCEPT

    -- actors who have co-starred with RUSSEL BACALL
    SELECT 
        a1.actor_id
    FROM actor a1
    JOIN film_actor fa1 ON fa1.actor_id=a1.actor_id
    JOIN film_actor fa2 ON fa1.film_id=fa2.film_id
    JOIN actor a2 ON fa2.actor_id=a2.actor_id
    WHERE a2.actor_id = 112
);

-- (-6) If you got too many rows in your output.
-- This was commonly caused by a dumb typo in a subquery that was not sanity checked.
SELECT DISTINCT
    a.first_name,
    a.last_name
FROM
    actor a
JOIN
    film_actor fa1 ON a.actor_id = fa1.actor_id
JOIN
    film f1 ON fa1.film_id = f1.film_id
JOIN
    film_actor fa2 ON f1.film_id = fa2.film_id
JOIN
    actor a2 ON fa2.actor_id = a2.actor_id
WHERE
    f1.title = 'AGENT TRUMAN'
    AND a.actor_id NOT IN (
        SELECT
            a.actor_id
        FROM
            actor a
        JOIN
            film_actor fa ON a.actor_id = fa.actor_id
        JOIN
            film f ON fa.film_id = f.film_id
        JOIN
            film_actor fa3 ON f.film_id = fa3.film_id
        JOIN
            actor a3 ON fa3.actor_id = a3.actor_id
        WHERE
            a3.first_name = 'RUSSEL'  -- TYPO HERE!
            AND a3.last_name = 'BACALL'
    );

/* PROBLEM 4:
 *
 * You want to watch a movie tonight.
 * But you're superstitious,
 * and don't want anything to do with the letter 'F'.
 * List the titles of all movies that:
 * 1) do not have the letter 'F' in their title,
 * 2) have no actors with the letter 'F' in their names (first or last),
 * 3) have never been rented by a customer with the letter 'F' in their names (first or last).
 *
 * NOTE:
 * Your results should not contain any duplicate titles.
 */


SELECT DISTINCT
    title
FROM film
WHERE 

  -- PART I
  title NOT ILIKE '%F%'

  -- PART II
  AND film_id NOT IN (
    SELECT
        film_id
    FROM actor
    JOIN film_actor USING (actor_id)
    WHERE first_name ILIKE '%F%'
       OR last_name ILIKE '%F%'
    )

  -- PART III
  AND film_id NOT IN (
    SELECT
        film_id
    FROM inventory
    JOIN rental USING (inventory_id)
    JOIN customer USING (customer_id)
    WHERE first_name ILIKE '%F%'
       OR last_name ILIKE '%F%'
    )
ORDER BY title;

-- GRADING

-- (-6) Getting too many rows.
-- This was almost always caused by forgetting that each row is independent,
-- and so filtering one row that mentions a customer with an 'F' will not fillter other rows without that customer.
SELECT DISTINCT
    film.title
FROM
    film
JOIN
    film_actor ON film.film_id = film_actor.film_id
JOIN
    actor ON film_actor.actor_id = actor.actor_id
JOIN
    inventory ON film.film_id = inventory.film_id
JOIN
    rental ON inventory.inventory_id = rental.inventory_id
JOIN
    customer ON rental.customer_id = customer.customer_id
WHERE
    film.title NOT LIKE '%F%'
    AND NOT EXISTS (
        SELECT 1
        FROM actor a
        WHERE a.actor_id = film_actor.actor_id
        AND (a.first_name LIKE '%F%' OR a.last_name LIKE '%F%')
        AND film.film_id = film_actor.film_id
    )
    AND NOT EXISTS (
        SELECT 1
        FROM customer c
        JOIN rental r ON c.customer_id = r.customer_id
        JOIN inventory i ON r.inventory_id = i.inventory_id
        WHERE c.customer_id = rental.customer_id
        AND (c.first_name LIKE '%F%' OR c.last_name LIKE '%F%')
        AND i.film_id = film.film_id
    )
ORDER BY
    film.title;


-- OTHER GRADING NOTES:
--
-- If you submitted something that generated syntax errors:
-- - You got a -8 if I couldn't figure out what was wrong
-- - You got a -2 if it was something I could easily fix
--
-- There's a handful of people that got -2 on problems for "almost" correct solutions.
--
-- I'm happy to go over grading with anyone who has questions.
