import { NextResponse } from 'next/server';
import { getPool } from '@/lib/db';

const QUERIES = [
  {
    id: 1,
    title: 'Total Assets by User',
    description: 'List all users with their total asset count and total value',
    query: `SELECT u.ID, u.Name, u.Email, COUNT(da.ID) AS TotalAssets, COALESCE(SUM(da.Value), 0) AS TotalAssetValue 
            FROM [USER] u LEFT JOIN DIGITAL_ASSET da ON u.ID = da.USER_ID 
            GROUP BY u.ID, u.Name, u.Email ORDER BY TotalAssetValue DESC;`
  },
  {
    id: 2,
    title: 'Top 5 Financial Assets',
    description: 'Top 5 users by financial asset value',
    query: `SELECT TOP 5 u.Name AS AssetOwner, SUM(fa.Balance) AS TotalBankBalance 
            FROM [USER] u JOIN DIGITAL_ASSET da ON u.ID = da.USER_ID 
            JOIN FINANCIAL_ASSET fa ON da.ID = fa.Digital_Asset_ID 
            GROUP BY u.ID, u.Name ORDER BY TotalBankBalance DESC;`
  },
  {
    id: 3,
    title: 'Pending Transfers',
    description: 'All pending transfers with owner, beneficiary, and asset info',
    query: `SELECT at.ID AS TransferID, u.Name AS AssetOwner, da.Name AS AssetName, da.Type AS AssetType, 
            b.Name AS Beneficiary, te.EventType AS TriggerType, te.EventDate AS EventDate, at.Status 
            FROM ASSET_TRANSFER at JOIN DIGITAL_ASSET da ON at.Digital_Asset_ID = da.ID 
            JOIN [USER] u ON da.USER_ID = u.ID JOIN BENEFICIARY b ON at.BeneficiaryID = b.ID 
            JOIN TRIGGER_EVENT te ON at.TRIGGER_EVENT_ID = te.ID WHERE at.Status = 'Pending';`
  },
  {
    id: 4,
    title: 'Beneficiaries with Multiple Assets',
    description: 'Beneficiaries assigned to more than one digital asset',
    query: `SELECT b.ID, b.Name AS BeneficiaryName, b.Email, COUNT(dab.Digital_Asset_ID) AS AssignedAssets 
            FROM BENEFICIARY b JOIN DIGITAL_ASSET_BENEFICIARY dab ON b.ID = dab.BeneficiaryID 
            GROUP BY b.ID, b.Name, b.Email HAVING COUNT(dab.Digital_Asset_ID) > 1 ORDER BY AssignedAssets DESC;`
  },
  {
    id: 6,
    title: 'Trigger Events Trend',
    description: 'Monthly trend of trigger events',
    query: `SELECT YEAR(EventDate) AS Year, MONTH(EventDate) AS Month, DATENAME(month, EventDate) AS MonthName, 
            COUNT(*) AS EventCount, SUM(CASE WHEN Status = 'Verified' THEN 1 ELSE 0 END) AS Verified, 
            SUM(CASE WHEN Status = 'Pending' THEN 1 ELSE 0 END) AS Pending, SUM(CASE WHEN Status = 'Rejected' THEN 1 ELSE 0 END) AS Rejected 
            FROM TRIGGER_EVENT GROUP BY YEAR(EventDate), MONTH(EventDate), DATENAME(month, EventDate) ORDER BY Year, Month;`
  },
  {
    id: 9,
    title: 'Asset Distribution',
    description: 'Assets per type with average value and total count',
    query: `SELECT Type, COUNT(*) AS AssetCount, ROUND(AVG(COALESCE(Value, 0)), 2) AS AvgValue, SUM(COALESCE(Value, 0)) AS TotalValue 
            FROM DIGITAL_ASSET GROUP BY Type;`
  },
  {
    id: 14,
    title: 'Digital Estate Summary',
    description: 'Summary of each user digital estate',
    query: `SELECT u.Name AS UserName, COUNT(da.ID) AS TotalAssets, 
            SUM(CASE WHEN da.Type = 'Financial' THEN 1 ELSE 0 END) AS FinancialAssets, 
            SUM(CASE WHEN da.Type = 'SocialMedia' THEN 1 ELSE 0 END) AS SocialAssets, 
            SUM(CASE WHEN da.Type = 'CloudStorage' THEN 1 ELSE 0 END) AS CloudAssets, 
            COALESCE(SUM(fa.Balance), 0) AS TotalBankBalance, COUNT(md.ID) AS MemoryItems 
            FROM [USER] u LEFT JOIN DIGITAL_ASSET da ON u.ID = da.USER_ID 
            LEFT JOIN FINANCIAL_ASSET fa ON da.ID = fa.Digital_Asset_ID LEFT JOIN MEMORY_DATA md ON u.ID = md.USER_ID 
            GROUP BY u.ID, u.Name ORDER BY TotalBankBalance DESC;`
  }
];

export async function GET(request: Request) {
  const { searchParams } = new URL(request.url);
  const qId = searchParams.get('id');

  if (!qId) {
    return NextResponse.json({ queries: QUERIES });
  }

  const queryObj = QUERIES.find(q => q.id === parseInt(qId));
  if (!queryObj) {
    return NextResponse.json({ error: 'Query not found' }, { status: 404 });
  }

  try {
    const pool = await getPool();
    const result = await pool.request().query(queryObj.query);
    return NextResponse.json({ data: result.recordset, columns: Object.keys(result.recordset[0] || {}) });
  } catch (error: unknown) {
    const message = error instanceof Error ? error.message : 'Unknown database error';
    return NextResponse.json({ error: message }, { status: 500 });
  }
}
