-- Always verify the output before executing

-- Be sure the pgvectore extensions enabled.
CREATE EXTENSION IF NOT EXISTS vector;

-- Create the emails table.
CREATE TABLE emails (
  id SERIAL PRIMARY KEY,
  subject TEXT NOT NULL,
  sender TEXT NOT NULL,
  recipient TEXT [] NOT NULL,
  cc TEXT [],
  bcc TEXT [],
  body TEXT NOT NULL NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create the email_sections table.
CREATE TABLE email_sections (
  id SERIAL PRIMARY KEY, --unique id for each section
  email_id INT NOT NULL REFERENCES emails (id) ON DELETE CASCADE,
  section_content TEXT NOT NULL, --content of the section (chunk)
  embedding VECTOR(1536),
  section_order INT, --order of the section in the original email
  created_at TIMESTAMPTZ DEFAULT NOW()
);

--Create an HNSW index on the section embeddings using the correct operator class.
--Euclidean Distance (vectore_l2_ops) would best for image or spatial data.
--Negative Inner Product (vector_ip_ops) would best for recommendation systems. 
--Cosine Distance (vector_cosine_ops) best for text and semantic search. 
CREATE INDEX section_embedding_hnsw_idx
ON email_sections USING hnsw (embedding vector_cosine_ops);
