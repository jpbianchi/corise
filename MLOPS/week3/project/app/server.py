from fastapi import FastAPI
from pydantic import BaseModel
from loguru import logger
import datetime
import json
from .classifier import NewsCategoryClassifier  # I had to add a dot before classifier, otherwise not found during tests


class PredictRequest(BaseModel):
    source: str
    url: str
    title: str
    description: str


class PredictResponse(BaseModel):
    scores: dict
    label: str


MODEL_PATH = "../data/news_classifier.joblib"
LOGS_OUTPUT_PATH = "../data/logs.out"

app = FastAPI()
nc = None

@app.on_event("startup")
def startup_event():
    """
    [TO BE IMPLEMENTED]
    1. Initialize an instance of `NewsCategoryClassifier`.
    2. Load the serialized trained model parameters (pointed to by `MODEL_PATH`) into the NewsCategoryClassifier you initialized.
    3. Open an output file to write logs, at the destimation specififed by `LOGS_OUTPUT_PATH`
        
    Access to the model instance and log file will be needed in /predict endpoint, make sure you
    store them as global variables
    """
    global nc
    nc = NewsCategoryClassifier(verbose=True)
    nc.load(MODEL_PATH)
    logger.info("Setup completed")


@app.on_event("shutdown")
def shutdown_event():
    # clean up
    """
    [TO BE IMPLEMENTED]
    1. Make sure to flush the log file and close any file pointers to avoid corruption
    2. Any other cleanups
    """
    logger.info("Shutting down application")
    with open(LOGS_OUTPUT_PATH, "w+") as f:
        f.flush()
        f.close()


@app.post("/predict", response_model=PredictResponse)
def predict(request: PredictRequest):
    # get model prediction for the input request
    # construct the data to be logged
    # construct response
    """
    [TO BE IMPLEMENTED]
    1. run model inference and get model predictions for model inputs specified in `request`
    2. Log the following data to the log file (the data should be logged to the file that was opened in `startup_event`)
    {
        'timestamp': <YYYY:MM:DD HH:MM:SS> format, when the request was received,
        'request': dictionary representation of the input request,
        'prediction': dictionary representation of the response,
        'latency': time it took to serve the request, in millisec
    }
    3. Construct an instance of `PredictResponse` and return
    """
    start = datetime.datetime.now()
    if nc == None:
        startup_event()

    # get model prediction for the input request
    predictions = nc.run_prediction(request)
    sorted_predictions = dict(sorted(predictions.items(), key=lambda item: item[1], reverse=True))
    label = list(sorted_predictions)[0]

    end = datetime.datetime.now()
    latency = (end - start).total_seconds() * 1000

    # construct the data to be logged
    logger.info(LogRequestResponse(request=request.dict(), prediction=sorted_predictions, latency=latency).json())

    # construct response
    return PredictResponse(scores=sorted_predictions, label=label)

    # response = PredictResponse(scores={"label1": 0.9, "label2": 0.1}, label="label1")
    # return response


@app.get("/")
def read_root():
    return {"Hello": "World"}
