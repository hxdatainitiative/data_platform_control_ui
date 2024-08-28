# Dockerfile

FROM python:3.9-slim

# Set working directory
WORKDIR /app

# Install dependencies
COPY src/requirements.txt requirements.txt
RUN pip install -r requirements.txt

# Copy the rest of the application
COPY  src/streamlit_app/ .

# Expose port
EXPOSE 8501

# Command to run the application
CMD ["streamlit", "run", "app.py"]
