import time
from typing import List, Dict
from tqdm import tqdm
import os
import multiprocessing
from w1.data_processor import DataProcessor
import constants
from global_utils import get_file_name, make_dir, plot_sales_data
import json
import argparse
from datetime import datetime
from pprint import pprint

CURRENT_FOLDER_NAME = os.path.dirname(os.path.abspath(__file__))


class DP(DataProcessor):
    def __init__(self, file_path: str) -> None:
        super().__init__(file_path)

    def get_file_path(self) -> str:
        return self._fp

    def get_file_name(self) -> str:
        return self._file_name

    def get_n_rows(self) -> int:
        return self._n_rows


def revenue_per_region(dp: DP) -> Dict:
    data_reader = dp.data_reader
    data_reader_gen = (row for row in data_reader)

    # skip first row as it is the column name
    _ = next(data_reader_gen)

    aggregate = dict()

    for row in tqdm(data_reader_gen):
        if row[constants.OutDataColNames.COUNTRY] not in aggregate:
            aggregate[row[constants.OutDataColNames.COUNTRY]] = 0
        aggregate[row[constants.OutDataColNames.COUNTRY]] += dp.to_float(row[constants.OutDataColNames.TOTAL_PRICE])

    return aggregate


def get_sales_information(file_path: str) -> Dict:
    # Initialize
    dp = DP(file_path=file_path)

    # print stats
    dp.describe(column_names=[constants.OutDataColNames.UNIT_PRICE, constants.OutDataColNames.TOTAL_PRICE])

    # return total revenue and revenue per region
    return {
        'total_revenue': dp.aggregate(column_name=constants.OutDataColNames.TOTAL_PRICE),
        'revenue_per_region': revenue_per_region(dp),
        'file_name': get_file_name(file_path)
    }


# batches the files based on the number of processes
def batch_files(file_paths: List[str], n_processes: int) -> List[set]:
    if n_processes > len(file_paths):
        return []

    n_per_batch = len(file_paths) // n_processes

    first_set_len = n_processes * n_per_batch
    first_set = file_paths[:first_set_len]
    second_set = file_paths[first_set_len:]

    batches = [set(file_paths[i:i + n_per_batch]) for i in range(0, len(first_set), n_per_batch)]
    for ind, each_file in enumerate(second_set):
        batches[ind].add(each_file)

    return batches


# Fetch the revenue data from a file
def run(n_process: int, batch: List[str]) -> List[Dict]:
    # I modified the order of arguments to be able to use enumerate
    st = time.time()

    print("Process : {}".format(n_process))
    folder_path = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'data')
    file_paths = [os.path.join(folder_path, file_name) for file_name in batch]
    revenue_data = [get_sales_information(file_path) for file_path in file_paths]

    en = time.time()

    print(f"Batch for process-{n_process} time taken {en - st}")
    return revenue_data


def flatten(lst: List[List]) -> List:
    return [item for sublist in lst for item in sublist]


def main() -> List[Dict]:
    """
    Use the `batch_files` method to create batches of files that needs to be run in each process
    Use the `run` method to fetch revenue data for a given batch of files

    Use multiprocessing module to process batches of data in parallel
    Check `multiprocessing.Pool` and `pool.starmap` methods to help you wit the task

    At the end check the overall time taken in this code vs the time taken in W1 code


    :return: Revenue data in the below format

    [{
        'total_revenue': float,
        'revenue_per_region': {
                                'China': float,
                                'France': float,
                                'Germany': float,
                                'India': float,
                                'Italy': float,
                                'Japan': float,
                                'Russia': float,
                                'United Kingdom': float,
                                'United States': float},
        'file_name': str
    },{
        'total_revenue': float,
        'revenue_per_region': {
                                'China': float,
                                'France': float,
                                'Germany': float,
                                'India': float,
                                'Italy': float,
                                'Japan': float,
                                'Russia': float,
                                'United Kingdom': float,
                                'United States': float},
        'file_name': str
    },
    ....
    ....
    ....
    ]
    """

    st = time.time()
    n_processes = 3 # you may modify this number - check out multiprocessing.cpu_count() as well

    parser = argparse.ArgumentParser(description="Choose from one of these : [tst|sml|bg]")
    parser.add_argument('--type',
                        default='tst',
                        choices=['tst', 'sml', 'bg'],
                        help='Type of data to generate')
    args = parser.parse_args()

    data_folder_path = os.path.join(CURRENT_FOLDER_NAME, '..', constants.DATA_FOLDER_NAME, args.type)
    files = [str(file) for file in os.listdir(data_folder_path) if str(file).endswith('csv')]

    output_save_folder = os.path.join(CURRENT_FOLDER_NAME, '..', 'output', args.type,
                                      datetime.now().strftime("%B %d %Y %H-%M-%S"))
    make_dir(output_save_folder)
    file_paths = [os.path.join(data_folder_path, file_name) for file_name in files]

    batches = batch_files(file_paths=file_paths, n_processes=n_processes)

    ######################################## YOUR CODE HERE ##################################################
    with multiprocessing.Pool(n_processes) as pool:
        year_sales_information = pool.starmap(run, enumerate(batches,1))
        pool.close()
        pool.join()

    # the following was not requested
    global_revenue = sum(ysi['total_revenue'] for ysi in flatten(year_sales_information))
    global_sales_region = {}
    for ysi in flatten(year_sales_information):
        for region,val in ysi['revenue_per_region'].items():
            global_sales_region[region] = global_sales_region.get(region,0) + val


    ######################################## YOUR CODE HERE ##################################################

    en = time.time()
    print("Overall time taken : {}".format(en-st))

    # should return revenue data
    return [global_revenue, global_sales_region, year_sales_information]


if __name__ == '__main__':
    res = main()
    pprint(res)
# Batch for process-1 time taken 6.642049074172974
# Overall time taken : 8.093858003616333
# [18595865.773998257,
#  {'Canada': 1529195.606000018,
#   'China': 854765.8540000042,
#   'France': 1971549.199000021,
#   'Germany': 1763358.3810000275,
#   'India': 1576388.037000024,
#   'Italy': 993264.8990000009,
#   'Japan': 1137640.2220000064,
#   'Russia': 715888.1219999996,
#   'United Kingdom': 4113848.336000083,
#   'United States': 3939967.118000091},

# [[{'file_name': '2015',
#     'revenue_per_region': {'Canada': 247533.6530000024,
#                            'China': 51774.16399999985,
#                            'France': 119369.79100000022,
#                            'Germany': 204774.97300000163,
#                            'India': 201626.9990000025,
#                            'Italy': 67568.26399999991,
#                            'Japan': 44309.01699999988,
#                            'Russia': 60171.94899999968,
#                            'United Kingdom': 685182.7670000093,
#                            'United States': 583203.0990000105},
#     'total_revenue': 2265514.6759997993},
#    {'file_name': '2016',
#     'revenue_per_region': {'Canada': 207364.0540000017,
#                            'China': 169964.3000000024,
#                            'France': 174285.64300000158,
#                            'Germany': 228622.34300000183,
#                            'India': 97026.50399999924,
#                            'Italy': 138269.71300000025,
#                            'Japan': 71622.25999999979,
#                            'Russia': 45781.22699999985,
#                            'United Kingdom': 630323.3500000136,
#                            'United States': 419037.2130000155},
#     'total_revenue': 2182296.6069997083},
#    {'file_name': '2021',
#     'revenue_per_region': {'Canada': 224466.37800000276,
#                            'China': 178841.42299999972,
#                            'France': 573300.703000005,
#                            'Germany': 310207.3060000097,
#                            'India': 372652.3250000077,
#                            'Italy': 118157.19199999984,
#                            'Japan': 160583.25300000157,
#                            'Russia': 133398.88599999968,
#                            'United Kingdom': 452913.5850000163,
#                            'United States': 537472.2310000153},
#     'total_revenue': 3061993.281999771}],
#   [{'file_name': '2018',
#     'revenue_per_region': {'Canada': 287601.0460000032,
#                            'China': 58386.56099999999,
#                            'France': 188809.5070000001,
#                            'Germany': 253318.01300000332,
#                            'India': 287511.7260000068,
#                            'Italy': 392247.32000000175,
#                            'Japan': 417741.0010000028,
#                            'Russia': 87113.61999999965,
#                            'United Kingdom': 441788.1390000169,
#                            'United States': 440614.4000000158},
#     'total_revenue': 2855131.3329997472},
#    {'file_name': '2017',
#     'revenue_per_region': {'Canada': 130638.25999999946,
#                            'China': 265652.0400000029,
#                            'France': 237453.06700000254,
#                            'Germany': 184073.31300000224,
#                            'India': 112640.22499999957,
#                            'Italy': 57025.70499999982,
#                            'Japan': 195540.3990000015,
#                            'Russia': 109440.61199999988,
#                            'United Kingdom': 332955.9580000077,
#                            'United States': 456055.5290000164},
#     'total_revenue': 2081475.1079997467}],
#   [{'file_name': '2019',
#     'revenue_per_region': {'Canada': 175110.00200000269,
#                            'China': 55695.04999999969,
#                            'France': 163828.34700000272,
#                            'Germany': 344793.15700000414,
#                            'India': 219366.78700000426,
#                            'Italy': 100696.18999999945,
#                            'Japan': 104515.45399999959,
#                            'Russia': 128354.35799999995,
#                            'United Kingdom': 713101.2420000108,
#                            'United States': 698517.7070000046},
#     'total_revenue': 2703978.2939997506},
#    {'file_name': '2020',
#     'revenue_per_region': {'Canada': 256482.2130000059,
#                            'China': 74452.31599999977,
#                            'France': 514502.14100000897,
#                            'Germany': 237569.27600000473,
#                            'India': 285563.4710000039,
#                            'Italy': 119300.51499999993,
#                            'Japan': 143328.8380000012,
#                            'Russia': 151627.47000000102,
#                            'United Kingdom': 857583.2950000089,
#                            'United States': 805066.9390000126},
#     'total_revenue': 3445476.4739997345}]]]