import 'reflect-metadata';
import * as fs from 'fs';
import * as path from 'path';
import { parse } from 'csv-parse';
import { HBNBaseComponent, HBNResult, HBNComponent } from '@hbn/base';

interface HBNFoodStore {
  연번: string;
  인허가관할기관: string;
  업소명: string;
  업종: string;
  업태: string;
  업소주소: string;
}

@HBNComponent()
class HBNFoodFilterComponent extends HBNBaseComponent {
  private csvPath: string = '';

  initComponent(): void {
    const opts = this.getOptions();
    this.csvPath = (opts as any).csvPath ?? '';
  }

  async filterByChangwon(): Promise<HBNFoodStore[]> {
    return new Promise((resolve, reject) => {
      const stores: HBNFoodStore[] = [];

      fs.createReadStream(this.csvPath, { encoding: 'utf-8' })
        .pipe(
          parse({
            columns: true,
            skip_empty_lines: true,
            trim: true,
          }),
        )
        .on('data', (row: HBNFoodStore) => {
          if (
            row.인허가관할기관?.includes('창원') ||
            row.업소주소?.includes('창원')
          ) {
            stores.push(row);
          }
        })
        .on('end', () => resolve(stores))
        .on('error', reject);
    });
  }
}

async function main(): Promise<void> {
  const csvPath = path.resolve(__dirname, '../../../..', 'data/food_stores.csv');

  if (!fs.existsSync(csvPath)) {
    console.error(`CSV 파일을 찾을 수 없습니다: ${csvPath}`);
    process.exit(1);
  }

  const filter = new HBNFoodFilterComponent({ csvPath });

  try {
    const stores = await filter.filterByChangwon();

    const result = HBNResult.resultSuccess({
      total: stores.length,
      stores,
    });

    console.log(`\n창원 지역 음식점 추출 완료`);
    console.log(`총 ${result.result.item?.total ?? 0}개 업소\n`);

    const outputPath = path.resolve(__dirname, '../changwon_food_stores.json');
    fs.writeFileSync(outputPath, JSON.stringify(result, null, 2), 'utf-8');
    console.log(`결과 저장: ${outputPath}`);

    stores.slice(0, 5).forEach((s, i) => {
      console.log(`\n[${i + 1}] ${s.업소명}`);
      console.log(`    업종: ${s.업종} / ${s.업태}`);
      console.log(`    주소: ${s.업소주소}`);
    });
  } catch (err) {
    const errorResult = HBNResult.resultError(err);
    console.error('오류 발생:', JSON.stringify(errorResult, null, 2));
    process.exit(1);
  }
}

main();
