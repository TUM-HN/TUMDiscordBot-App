"""
Contains API endpoints for retrieving data files.

:copyright: (c) 2023-present Ivan Parmacli
:license: MIT, see LICENSE for more details.
"""

import os
import csv
from pathlib import Path
from flask import Blueprint, jsonify, request, abort
from typing import List, Dict
from datetime import datetime
from REST.api.api_validation import requires_api_key

data_bp = Blueprint('data', __name__)

# Determine the absolute project root (two levels up from this file: REST/bot_manager/.. -> REST -> project root)
# This avoids issues when the Flask app is started from a different working directory.
PROJECT_ROOT = Path(__file__).resolve().parents[2]
BASE_DATA_DIR = PROJECT_ROOT / 'data'

# Ensure the data directory exists; create it if it does not (prevents FileNotFoundError downstream)
BASE_DATA_DIR.mkdir(exist_ok=True, parents=True)

def get_files_in_directory(directory: Path) -> List[Dict[str, str]]:
    """
    Get all files in a directory with their metadata.
    
    Args:
        directory (Path): The directory path to scan
        
    Returns:
        List[Dict[str, str]]: List of files with their metadata
    """
    files = []
    try:
        for filename in os.listdir(directory):
            if filename.startswith('.'):  # Skip hidden files
                continue
                
            file_path = directory / filename
            if file_path.is_file():
                # Get file metadata
                stat = file_path.stat()
                files.append({
                    'name': filename,
                    'size': stat.st_size,
                    'created': datetime.fromtimestamp(stat.st_ctime).isoformat(),
                    'modified': datetime.fromtimestamp(stat.st_mtime).isoformat()
                })
    except FileNotFoundError:
        return []
        
    return sorted(files, key=lambda x: x['modified'], reverse=True)

def read_csv_file(file_path: Path) -> List[Dict[str, str]]:
    """
    Read a CSV file and return its contents as a list of dictionaries.
    
    Args:
        file_path (Path): Path to the CSV file
        
    Returns:
        List[Dict[str, str]]: List of dictionaries containing the CSV data
    """
    try:
        with open(file_path, 'r', encoding='utf-8') as file:
            csv_reader = csv.DictReader(file)
            return list(csv_reader)
    except Exception as e:
        return []

@data_bp.route('/api/data/feedback', methods=['GET'])
@requires_api_key
def get_feedback_files():
    """
    Get all available feedback files or content of a specific file.
    
    Query Parameters:
        api_key (str): API key for authentication
        file (str, optional): Specific file to retrieve content from
        
    Returns:
        JSON response with list of files or file content
    """
    feedback_dir = BASE_DATA_DIR / 'tutor_session_feedback'
    file_name = request.args.get('file')
    
    if file_name:
        file_path = feedback_dir / file_name
        if not file_path.is_file():
            abort(404, description="File not found")
        content = read_csv_file(file_path)
        return jsonify({'content': content})
    
    files = get_files_in_directory(feedback_dir)
    return jsonify({'files': files})

@data_bp.route('/api/data/surveys', methods=['GET'])
@requires_api_key
def get_survey_files():
    """
    Get all available survey files or content of a specific file.
    
    Query Parameters:
        api_key (str): API key for authentication
        file (str, optional): Specific file to retrieve content from
        
    Returns:
        JSON response with list of files or file content
    """
    survey_dir = BASE_DATA_DIR / 'exercise_feedback'
    file_name = request.args.get('file')
    
    if file_name:
        file_path = survey_dir / file_name
        if not file_path.is_file():
            abort(404, description="File not found")
        content = read_csv_file(file_path)
        return jsonify({'content': content})
    
    files = get_files_in_directory(survey_dir)
    return jsonify({'files': files})

@data_bp.route('/api/data/attendance', methods=['GET'])
@requires_api_key
def get_attendance_files():
    """
    Get all available attendance files or content of a specific file.
    
    Query Parameters:
        api_key (str): API key for authentication
        file (str, optional): Specific file to retrieve content from
        
    Returns:
        JSON response with list of files or file content
    """
    attendance_dir = BASE_DATA_DIR / 'attendance'
    file_name = request.args.get('file')
    
    if file_name:
        file_path = attendance_dir / file_name
        if not file_path.is_file():
            abort(404, description="File not found")
        content = read_csv_file(file_path)
        return jsonify({'content': content})
    
    files = get_files_in_directory(attendance_dir)
    return jsonify({'files': files}) 