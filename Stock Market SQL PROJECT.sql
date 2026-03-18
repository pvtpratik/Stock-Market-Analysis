create database stock_market;
use stock_market;

select * from stocks;
select * from dim_company;
select * from fact_daily_prices;
select * from fact_divident;
select * from fact_orders;
select * from fact_trades;

-- 1. MARKET CAPITALIZATION --

SELECT company_name, (share_price * outstanding_shares) AS Market_capitalization FROM stocks ORDER BY Market_capitalization DESC;

-- 2. AVERAGE TRADING VOLUME --

SELECT d.ticker, AVG(f.volume) AS Avg_Trading_Volume
FROM fact_daily_prices f
	JOIN dim_company d
		ON f.company_id = d.company_id
	GROUP BY d.ticker
    ORDER BY Avg_Trading_Volume DESC;
    
-- 3. VOLATILITY --

SELECT
    c.company_name,
    CONCAT(
        ROUND(
            STDDEV(dr.daily_return) * 100,
            3
        ),
        '%'
    ) AS volatility_pct
FROM
(
    SELECT
        f.company_id,
        (f.adjusted_close - LAG(f.adjusted_close) OVER (
            PARTITION BY f.company_id
            ORDER BY f.date
        )) / LAG(f.adjusted_close) OVER (
            PARTITION BY f.company_id
            ORDER BY f.date
        ) AS daily_return
    FROM fact_daily_prices f
) dr
JOIN dim_company c
    ON dr.company_id = c.company_id
WHERE dr.daily_return IS NOT NULL
GROUP BY c.company_name
ORDER BY
    STDDEV(dr.daily_return) DESC;


-- 4. TOP PERFORMING SECTOR --

SELECT
    s.sector,
    ROUND(AVG(dr.daily_return) * 100, 3) AS Top_Performing_Sector
FROM
(
    SELECT
        f.company_id,
        (f.adjusted_close - LAG(f.adjusted_close) OVER (
            PARTITION BY f.company_id
            ORDER BY f.date
        )) / LAG(f.adjusted_close) OVER (
            PARTITION BY f.company_id
            ORDER BY f.date
        ) AS daily_return
    FROM fact_daily_prices f
) dr
JOIN dim_company c
    ON dr.company_id = c.company_id
JOIN stocks s
    ON c.ticker = s.ticker
WHERE dr.daily_return IS NOT NULL
GROUP BY s.sector
ORDER BY Top_Performing_Sector DESC;

-- 5. PORTFOLIO VALUE --

SELECT
    ticker,
    company_name,
    quantity,
    quantity * share_price AS portfolio_value
FROM stocks;

-- 6. PORTFOLIO RETURN % -- 

SELECT
    company_name, sector,
   CONCAT(
        ROUND(
            ((current_value - initial_value) / initial_value) * 100,
            3
        ),
        '%'
    ) AS portfolio_return_pct
FROM stocks;

-- 7.DIVIDENT YIELD --

SELECT 
    s.company_name,
    CONCAT(
        ROUND(
            (f.dividend_per_share / s.share_price) * 100,
            3
        ),
        '%'
    ) AS dividend_yield
FROM fact_divident f
JOIN Dim_Company d 
    ON f.company_id = d.company_id
JOIN Stocks s 
    ON d.ticker = s.ticker;
    
-- 8. SHARP RATIO --

WITH daily_returns AS (
    SELECT
        company_id,
        (adjusted_close - LAG(adjusted_close) OVER (
            PARTITION BY company_id
            ORDER BY date
        )) / LAG(adjusted_close) OVER (
            PARTITION BY company_id
            ORDER BY date
        ) AS daily_return
    FROM fact_daily_prices
)
SELECT
    c.company_name,
    ROUND(
        (AVG(dr.daily_return) - 0.000238) / STDDEV(dr.daily_return),
        3
    ) AS Sharpe_Ratio
FROM daily_returns dr
JOIN dim_company c
    ON dr.company_id = c.company_id
WHERE dr.daily_return IS NOT NULL
GROUP BY c.company_name;

-- 9.ORDER EXECUTION RATE --

SELECT 
    d.company_name,
    ROUND(
        (SUM(CASE WHEN o.status = 'FILLED' THEN 1 ELSE 0 END) * 100.0) / COUNT(*),
        2
    ) AS Order_Execution_Rate
FROM Fact_Orders o
JOIN Dim_Company d 
    ON o.company_id = d.company_id
GROUP BY d.company_name;

-- 10. TRADE WIN RATE --

SELECT 
    d.company_name,
    ROUND(SUM(t.win_flag) * 100.0 / COUNT(*), 2) AS Trade_Win_Rate
FROM Fact_Trades t
JOIN Dim_Company d 
    ON t.company_id = d.company_id
GROUP BY d.company_name;

-- 11. TRADER PERFORMANCE --

SELECT 
    SUM(initial_value * quantity) AS Total_Sell_Value,
    SUM(buy_price * quantity) AS Total_Buy_Value,
    SUM((initial_value * quantity) - (buy_price * quantity)) AS Trader_Performance
FROM Stocks;

SELECT 
    company_name,
    SUM(initial_value * quantity) AS Sell_value,
    SUM(buy_price * quantity) AS Buy_value,
    SUM((initial_value * quantity) - (buy_price * quantity)) AS Trader_Performance
FROM Stocks
GROUP BY company_name;
























    
