import logging

def get_logger(name: str):
    logging.basicConfig(level=logging.INFO, format="%(levelname)s: %(name)s - %(message)s")
    return logging.getLogger(name)