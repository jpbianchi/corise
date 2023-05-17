# Run tests with prints 
```
PYTHONPATH=../ pytest test.py -s
```

# Run tests without prints 
```
PYTHONPATH=../ pytest test.py
```

# Run the data processing code
````
# Run on `test` data
PYTHONPATH=../ python main.py --type tst

# Run on `small` data
PYTHONPATH=../ python main.py --type sml

# Run on the `big` data
PYTHONPATH=../ python main.py --type bg
````

# Start FastAPI server
````
run the following code from the `w2` directory
PYTHONPATH=.. uvicorn server:app --workers 2
^^^ this is important otherwise it won't find some files
````