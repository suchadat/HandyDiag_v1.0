# HandyDiag

HandyDiag is a digital handwriting-based screening system for Parkinson's disease. This repository contains the MATLAB source code used in the study:

Theerasak Chanwimalueang, Kulthida Methawasin, Panuwat Saetee, Taksaporn Rueangrong, Busayamas Rung-ruang, Suchada Tantisatirapong. "Digital Thai Handwriting for Parkinson's Disease Screening". Scientific Reports, 2026.

*corresponding author: suchadat@g.swu.ac.th

## Citation

If you use this source code, dataset, or any part of this work in your research, publication, or derivative software, please cite the following article:

Users of this repository are requested to acknowledge and cite the above publication in any research work, publication, or software that uses or is derived from this code or dataset.


## Terms of Use

The HandyDiag dataset and source code are provided solely for non-commercial research and educational purposes.

Users of this repository are requested to cite the following publication in any research work, publication, presentation, thesis, dissertation, or software that uses or is derived from the dataset or source code:

Theerasak Chanwimalueang, Kulthida Methawasin, Panuwat Saetee, Taksaporn Rueangrong, Busayamas Rung-ruang, and Suchada Tantisatirapong. "Digital Thai Handwriting for Parkinson's Disease Screening". Scientific Reports, 2026.

Commercial use of the HandyDiag dataset, source code, or any derivative works is prohibited without prior written permission from the copyright holder.

For inquiries regarding commercial licensing, please contact:

Suchada Tantisatirapong
Department of Biomedical Engineering, Faculty of Engineering
Srinakharinwirot University
Email: suchadat@g.swu.ac.th


## Workflow Overview

The analysis pipeline consists of two main stages: data preprocessing and feature extraction, and machine learning model development and evaluation.

### 1. Data Preprocessing and Feature Extraction

The primary script `MainExtractionFeature_ML.m` performs data preprocessing and feature extraction by calling the following task-specific scripts:

* `extract_spiral_feature.m`
* `extract_lines_feature.m`
* `extract_letters_feature.m`

### 2. Feature Selection, Model Training, and Evaluation

Feature selection using Neighborhood Component Analysis (NCA), followed by model training and evaluation, is performed using:

* `evaluation_NCA_SVM.m` (Support Vector Machine)
* `evaluation_NCA_KNN.m` (K-Nearest Neighbors)
* `evaluation_NCA_DT.m` (Decision Tree)

## License

Copyright (c) 2024 Suchada Tantisatirapong
Department of Biomedical Engineering, Faculty of Engineering
Srinakhawirot University
Email: suchadat@g.swu.ac.th
All rights reserved.


