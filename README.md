# data-for-revolution-project
This is my data for my university paper on revolution, specifically what factors determine the outcome of a revolution. The idea came from my previous semester, when, as a class project, I did a very nice literature review on the evolution of revolution theories, and I had the idea of trying to quantifying and measuring revolutionary outcomes. I hope that this amounts to something interesting and publishable, but first and foremost, this is my assignment for the course of Measurement and Causes of Poverty. And because I am also a stickler for efficiency, this also doubles as my final assignment for the STATA Lab Course.

The data for GDP Per Capita comes from World Bank data. If World Bank data is unavailable (as is the case with Cuba and Venezuela), the CIA Factbook is used. Data for Life Expectancy is also sourced from The World Bank. The data is lagged one year compared to the event.

Data for whether the revolt is widespread or not is gathered by me, through news articles and research papers on the event in question. The variable takes the value of 1 (yes) if the revolt started in the urban center and spreaded to the rural area, or started in the rural area itself, and 0 otherwise. This is not subject to the time lag treatment.

The remaining data is indicators of the Fragile State Index published by the Fund For Peace, and is also subject to the time lag treatment.
