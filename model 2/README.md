# Background

The tables shown demonstrate the use of recursion to build hierarchies of content.

Within the application content can be an article or a collection. A collection can contain any number of articles or other collections.

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

The final table can be used to report on engagement on multiple collections that a piece of content might belong to.
