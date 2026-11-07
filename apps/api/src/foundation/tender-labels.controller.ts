import { Controller, Get } from '@nestjs/common';
import { ApiOkResponse, ApiProperty, ApiTags } from '@nestjs/swagger';
import { LOCAL_CARD_TRANSFER_LABEL } from 'money';

class TenderLabelsDto {
  @ApiProperty({ example: LOCAL_CARD_TRANSFER_LABEL })
  card!: string;

  @ApiProperty({ example: LOCAL_CARD_TRANSFER_LABEL })
  transfer!: string;
}

@ApiTags('foundation')
@Controller('foundation')
export class TenderLabelsController {
  @Get('tender-labels')
  @ApiOkResponse({ type: TenderLabelsDto })
  labels(): TenderLabelsDto {
    return {
      card: LOCAL_CARD_TRANSFER_LABEL,
      transfer: LOCAL_CARD_TRANSFER_LABEL,
    };
  }
}
