import constants
from w1.data_processor import DataProcessor
from pprint import pprint
from typing import Dict
from tqdm import tqdm
import os
import argparse
from global_utils import get_file_name, make_dir, plot_sales_data
from datetime import datetime
import json


CURRENT_FOLDER_NAME = os.path.dirname(os.path.abspath(__file__))


def revenue_per_region(dp: DataProcessor) -> Dict:
    """
    Input : object of instance type Class DataProcessor
    Output : Dict

    The method should find the aggregate revenue per region

    For example if the file format is as below:

    StockCode    , Description    , UnitPrice  , Quantity, TotalPrice , Country
    22180        , RETROSPOT LAMP , 19.96      , 4       , 79.84      , Russia
    23017        , APOTHECARY JAR , 24.96      , 1       , 24.96      , Germany
    84732D       , IVORY CLOCK    , 0.39       , 2       , 0.78       ,India
    ...
    ...
    ...

    expected output format is:
    {
        'China': 1.66,
        'France': 17.14,
        'Germany': 53.699999999999996,
        'India': 55.78,
        'Italy': 90.45,
        'Japan': 76.10000000000001,
        'Russia': 87.31,
        'United Kingdom': 29.05,
        'United States': 121.499
    }
    """
    ######################################## YOUR CODE HERE ##################################################
    total = {}
    # at this stage, dp.data_reader is not a generator yet
    # we must get the generator from data_reader, like this
    data_reader_gen = iter(dp.data_reader) # or dp.data_reader.__iter__()
    # or, like before, ie data_reader_gen = (row for row in dp.data_reader)

    # skip first row as it is the column name
    _ = next(data_reader_gen)
    for row in data_reader_gen:
        total[row[constants.OutDataColNames.COUNTRY]] = \
            total.get(row[constants.OutDataColNames.COUNTRY], 0.0) \
            + dp.to_float(row[constants.OutDataColNames.TOTAL_PRICE])
    return total
    ######################################## YOUR CODE HERE ##################################################


def get_sales_information(file_path: str, stats: bool = True) -> Dict:
    # Initialize
    dp = DataProcessor(file_path=file_path)

    # print stats
    if stats:
        dp.describe(column_names=[constants.OutDataColNames.UNIT_PRICE, constants.OutDataColNames.TOTAL_PRICE])

    # return total revenue and revenue per region
    return {
        'revenue_per_region': revenue_per_region(dp),
        'total_revenue': dp.aggregate(column_name=constants.OutDataColNames.TOTAL_PRICE),
        'file_name': get_file_name(file_path)
    }


def main():
    parser = argparse.ArgumentParser(description="Choose from one of these : [tst|sml|bg]")
    parser.add_argument('--type',
                        default='tst',
                        choices=['tst', 'sml', 'bg'],
                        help='Type of data to generate')
    parser.add_argument('--stats', default='True',
                        help='To skip stats (for debug)')
    args = parser.parse_args()
    args.stats = True if args.stats.lower() == 'true' else False

    data_folder_path = os.path.join(CURRENT_FOLDER_NAME, '..', constants.DATA_FOLDER_NAME, args.type)
    files = [str(file) for file in os.listdir(data_folder_path) if str(file).endswith('csv')]

    output_save_folder = os.path.join(CURRENT_FOLDER_NAME, '..', 'output', args.type,
                                      datetime.now().strftime("%B %d %Y %H-%M-%S"))
    make_dir(output_save_folder)

    file_paths = [os.path.join(data_folder_path, file_name) for file_name in files]
    revenue_data = [get_sales_information(file_path, stats=args.stats)
                    for file_path in file_paths]  # one path per year

    pprint(revenue_data)

    for yearly_data in revenue_data:
        with open(os.path.join(output_save_folder, f'{yearly_data["file_name"]}.json'), 'w') as f:
            f.write(json.dumps(yearly_data))

        plot_sales_data(yearly_revenue=yearly_data['revenue_per_region'], year=yearly_data["file_name"],
                        plot_save_path=os.path.join(output_save_folder, f'{yearly_data["file_name"]}.png'))


if __name__ == '__main__':
    main()

    # ...
    # {'file_name': '2021',
    #   'revenue_per_region': {'Canada': 224466.37800000276,
    #                          'China': 178841.42299999972,
    #                          'France': 573300.703000005,
    #                          'Germany': 310207.3060000097,
    #                          'India': 372652.3250000077,
    #                          'Italy': 118157.19199999984,
    #                          'Japan': 160583.25300000157,
    #                          'Russia': 133398.88599999968,
    #                          'United Kingdom': 452913.5850000163,
    #                          'United States': 537472.2310000153},
    #   'total_revenue': 3061993.281999771}]

