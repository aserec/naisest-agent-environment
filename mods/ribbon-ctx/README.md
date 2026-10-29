# ribbon-ctx

A fork of [ribbon](https://github.com/robonuggets/ribbon) 1.0.0 (MIT) by Jay E. It adds a `CTX` bar in front of 5H and 7D. The bar shows the context tokens in use, for example `112k / 300k`. It fills up at 300k tokens, even on a bigger window. The number is cream up to 150k tokens, yellow above 150k and red above 250k.

Load it with `claude --plugin-dir mods/ribbon-ctx`, and disable the original `ribbon` in `/plugin`. Test it with `claude plugin test mods/ribbon-ctx`.
