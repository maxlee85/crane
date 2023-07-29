CREATE OR REPLACE VIEW etl_staging_views.text_set_trees_base AS
/*
As of 3/28/2022, text sets can contain multiple types of content.
The content can be articles, videos and other text sets. This table aims to
represent the ancestral relationships of all text sets that are parents
to other text sets. There is no limit to the depth or breadth of text set trees,
so a recursive strategy is necessary to identify the full depth of the tree.
Any text set that has a child text set is counted as a "ancestor" text set, even
if that parent text set has a parent itself. In this table, there is a row
for each relationship between a text set and EACH of its ancestor text sets. For now,
if a text set does NOT have any children text sets it is not included in this
table.

On 3/21/2023 this table was updated to include text sets that did not have a
parent/child relationship. These text sets are considered standadlone text sets and
can be identified as is_standalone_text_set = 1. The depth_from_ancestor = 0 and
null parent text set details.
*/
WITH RECURSIVE tree (
    text_set_content_id,
    text_set_id,
    parent_text_set_content_id,
    parent_text_set_id,
    ancestor_text_set_content_id,
    ancestor_text_set_id,
    depth_from_ancestor,
    text_set_title,
    context
) AS (
    -- Recursion will start with ANY text set that is a parent to other text sets
    SELECT
        parent_text_set_content_id AS text_set_content_id,
        parent_text_set_id AS text_set_id,

        -- The ancestor text-set has no parent
        NULL AS parent_text_set_content_id,
        NULL AS parent_text_set_id,

        -- An ancestor text set's ancestor is itself
        parent_text_set_content_id AS ancestor_text_set_content_id,
        parent_text_set_id AS ancestor_text_set_id,

        -- Depth is 0 and ts title is only context
        -- because we are at the start of a new tree
        0 AS depth_from_ancestor,
        parent_text_set_title AS text_set_title,
        parent_text_set_title AS context
    FROM
        etl_staging.text_set_hierarchy
    UNION ALL
    SELECT
        -- Child text set is new leaf text set
        ts.child_text_set_content_id AS text_set_content_id,
        ts.child_text_set_id AS child_text_set_id,

        -- Previous leaf text set is new parent text set
        t.text_set_content_id AS parent_text_set_content_id,
        t.text_set_id AS parent_text_set_id,

        -- Ancestor text set is always the same within 1 tree
        t.ancestor_text_set_content_id AS ancestor_text_set_content_id,
        t.ancestor_text_set_id AS ancestor_text_set_id,

        -- Increment depth by 1
        t.depth_from_ancestor + 1 AS depth_from_ancestor,
        ts.child_text_set_title AS text_set_title,

        -- Concatenate the title of the new leaf onto the context of its parent
        t.context || ' -> ' || ts.child_text_set_title AS context
    FROM
        etl_staging.text_set_hierarchy ts
        JOIN tree t ON ts.parent_text_set_id = t.text_set_id
)
SELECT DISTINCT
    text_set_content_id,
    text_set_id,
    parent_text_set_content_id,
    parent_text_set_id,
    ancestor_text_set_content_id,
    ancestor_text_set_id,
    depth_from_ancestor,
    text_set_title,
    context,
    0 AS is_standalone_text_set
FROM
    tree
UNION ALL
SELECT
    ts.content_id AS text_set_content_id,
    ts.text_set_id,
    NULL AS parent_text_set_content_id,
    NULL AS parent_text_set_id,
    ts.content_id AS ancestor_text_set_content_id,
    ts.text_set_id AS ancestor_text_set_id,
    0::NUMBER(38,0) AS depth_from_ancestor,
    ts.text_set_title,
    ts.text_set_title AS context,
    1 AS is_standalone_text_set
FROM
    etl_dim.text_sets ts
WHERE
    NOT EXISTS (SELECT 1 FROM tree t WHERE ts.text_set_id = t.ancestor_text_set_id)
    AND ts.text_set_key > 0
;
