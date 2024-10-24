-- Function: match_filtered_email_sections
-- Description: This function retrieves relevant email sections based on a similarity search
-- using a vector embedding and allows filtering by the sender or recipient email address.

CREATE OR REPLACE FUNCTION match_filtered_email_sections(
    query_embedding VECTOR(1536),   -- Input: The embedding vector generated from the user's question (1536 dimensions for ADA-002).
    match_threshold FLOAT,          -- Input: Minimum similarity threshold (only sections with similarity above this will be returned).
    match_count INT,                -- Input: Maximum number of results to return.
    email_address TEXT              -- Input: The email address used to filter by sender or recipient.
) RETURNS TABLE (
    id INT,                         -- Output: Unique ID of the email section.
    email_id INT,                   -- Output: ID of the parent email (used to reference the full email).
    section_content TEXT,           -- Output: The content of the matching email section (a chunk of the email).
    similarity FLOAT                -- Output: Similarity score between the query embedding and the section embedding.
) LANGUAGE SQL AS $$
    -- Core SQL query to perform the similarity search and filter results.
    SELECT 
        es.id,                      -- Select the ID of the email section.
        es.email_id,               -- Select the ID of the parent email to which this section belongs.
        es.section_content,        -- Select the content of the section (chunk of the email).
        1 - (es.embedding <-> query_embedding) AS similarity -- Calculate similarity score: 1 minus the cosine distance.
    FROM 
        email_sections es           -- From the email sections table (contains all the email chunks with their embeddings).
    JOIN 
        emails e ON es.email_id = e.id -- Join with the emails table to access sender and recipient information.
    WHERE 
        -- Filter by sender or recipient: Only retrieve sections where the sender or recipient matches the given email address.
        (e.sender = email_address OR e.recipient @> ARRAY[email_address])
        -- Apply the similarity threshold: Only return sections with a similarity score greater than the threshold.
        AND (1 - (es.embedding <-> query_embedding)) > match_threshold
    ORDER BY 
        similarity DESC              -- Order the results by similarity in descending order (most similar first).
    LIMIT 
        LEAST(match_count, 200);     -- Limit the number of results to the smaller of match_count or 200 to prevent large queries.
$$;

-- Verify the existence of the function
SELECT * FROM pg_proc WHERE proname = 'match_filtered_email_sections';

-- Check schema and function details
SELECT 
    nspname AS schema_name, 
    proname AS function_name 
FROM 
    pg_proc p 
JOIN 
    pg_namespace n ON p.pronamespace = n.oid 
WHERE 
    proname = 'match_filtered_email_sections';
