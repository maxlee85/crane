# Background
Within our application access to content is determined by access to a text set. A text set can contain any content type or other text sets. Content can be an article, article header, video, etc...

For example
```
social studies text set
|── article 1
|── video 5
│── the history of texas text set
│   |── high school text set
│   |   ├── article 4
│   |   └── article header 7
│   |── middle school text set
│   |   |── article 7
│   |   └── district 1 middle school text set
│   |       └──article 10
```

The purpose of this project was to find for a piece of content, determine what text sets that content belongs to in order to measure engagement with text sets.

# Approach
Since there are not a fixed number of levels a piece of content can be nested in a text set, use recursion to create the parent child relationships.

# text_set_hierarchy
Parent child relationships are stored in 2 different tables so:
1. Determine the parent child relationships that exist for each table
2. Union all rows together to remove duplicates

# text_set_trees_base
This table performs the recursion.
1. The first select within the cte selects from text_set_hierarchy to select all parents and sets that as the ancestor (the very top level), determines the context (path of the hierarchy) and the depth from ancestor (how many levels away is something from the ancestor)
2. The 2nd select within the cte takes text_set_hierarchy and performs a join to the cte
3. Finally union all the rows from the cte to all orphan text sets (aka those without a parent child relationship)

# text_set_trees
Since there are multiple content types that can be stored in text_set_trees_base, join to every corresponding content type dimension to pull in the relevant columns.
