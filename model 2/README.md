# Background
Within our application content can be an article or a collection. A collection can contain any number of articles or other collections.

For example
```
social studies collection
|── article 1
|── article 2
│── the history of texas collection
│   |── high school collection
│   |   ├── article 4
│   |   └── article 7
│   |── middle school collection
│   |   |── article 7
│   |   └── district 1 middle school collection
│   |       └──article 10
```

The purpose of this project was to find for a piece of content, determine what collections that content belongs to to measure engagement across collections.

# Approach

Since there are not a fixed number of levels a piece of content can be nested in a collection, use recursion to create the parent child relationships.
