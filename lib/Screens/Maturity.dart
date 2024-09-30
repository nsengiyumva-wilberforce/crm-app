import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';
import 'package:vfu/Controllers/services.dart';
import 'package:vfu/Models/Maturity.dart';
import 'package:vfu/Utils/AppColors.dart';

import '../Widgets/Drawer/DrawerItems.dart';
import 'package:syncfusion_flutter_datagrid_export/export.dart';
import 'package:intl/intl.dart';

import 'package:syncfusion_flutter_xlsio/xlsio.dart' hide Column, Row;
import 'package:syncfusion_flutter_pdf/src/pdf/implementation/pdf_document/pdf_document.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:syncfusion_flutter_pdf/pdf.dart' as pdf;
import 'package:syncfusion_flutter_core/theme.dart';

class MaturityPage extends StatefulWidget {
  const MaturityPage({super.key});

  @override
  MaturityPageState createState() => MaturityPageState();
}

class MaturityPageState extends State<MaturityPage> {
  late Future<List<Maturity>> maturities;
  late MaturityDataSource maturityDataSource;
  final GlobalKey<SfDataGridState> _key = GlobalKey<SfDataGridState>();
  @override
  void initState() {
    super.initState();
    maturities = getMaturityData();
  }

  Future<void> exportDataGridToExcel() async {
    final Workbook workbook = _key.currentState!.exportToExcelWorkbook();
    final List<int> bytes = workbook.saveAsStream();

    // Get the temporary directory path
    final directory = await getTemporaryDirectory();
    // Generate the file path using the current date and time
    final path = '${directory.path}/Maturity_${DateTime.now()}.xlsx';

    // Write the file
    File(path).writeAsBytes(bytes).then((_) {
      // Open the file using platform agnostic API
      OpenFile.open(path);
    });

    workbook.dispose();
  }

  Future<void> _exportDataGridToPdf() async {
    final PdfDocument document = _key.currentState!.exportToPdfDocument(
      fitAllColumnsInOnePage: true,
      //set the header to "All Sales Activity"
      headerFooterExport:
          (DataGridPdfHeaderFooterExportDetails headerFooterExport) {
        final double width = headerFooterExport.pdfPage.getClientSize().width;
        final pdf.PdfPageTemplateElement header =
            pdf.PdfPageTemplateElement(Rect.fromLTWH(0, 0, width, 65));
        header.graphics.drawString(
          'Loans Maturing in this month and next month Report',
          pdf.PdfStandardFont(pdf.PdfFontFamily.helvetica, 13,
              style: pdf.PdfFontStyle.bold),
          bounds: const Rect.fromLTWH(0, 25, 800, 60),
        );
        // set the document to landscape
        headerFooterExport.pdfDocumentTemplate.top = header;
      },
    );

    //set the page orientation to landscape
    final List<int> bytes = document.saveSync();

    // Get the temporary directory path
    final directory = await getTemporaryDirectory();

    // generate the file path using the current date and time
    final path = '${directory.path}/Maturity_${DateTime.now()}.pdf';

    File(path).writeAsBytes(bytes).then((_) {
      // Open the file using platform agnostic API
      OpenFile.open(path);
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      drawer: Drawer(
        backgroundColor: AppColors.menuBackground,
        width: size.width * 0.8,
        child: const DrawerItems(),
      ),
      appBar: AppBar(
        iconTheme: IconThemeData(
          color: AppColors.menuBackground,
          size: size.width * 0.11,
        ), // Change the icon color here

        backgroundColor: AppColors.contentColorOrange,

        title: Text(
          "Maturity Loans",
          style: GoogleFonts.lato(
              fontSize: size.width * 0.062,
              color: AppColors.menuBackground,
              fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: FutureBuilder(
          future: maturities,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            //check if there is an error
            if (snapshot.hasError) {
              return Center(
                child: Text('Error: ${snapshot.error}'),
              );
            }

            //check if data is empty
            if (snapshot.data!.isEmpty) {
              return const Center(
                child: Text('No data found'),
              );
            }

            maturityDataSource = MaturityDataSource(
                maturityData: snapshot.data as List<Maturity>);
            return Column(
              children: [
                Container(
                  margin: const EdgeInsets.all(12.0),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: SizedBox(
                          height: 40.0,
                          child: MaterialButton(
                            color: AppColors.contentColorOrange,
                            onPressed: () {
                              exportDataGridToExcel();
                            },
                            child: const Center(
                              child: Icon(
                                Icons.description,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 20), // Adjusted to SizedBox
                      Expanded(
                        child: SizedBox(
                          height: 40.0,
                          child: MaterialButton(
                            color: AppColors.contentColorOrange,
                            onPressed: _exportDataGridToPdf,
                            child: const Center(
                              child: Icon(
                                Icons.picture_as_pdf,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SfDataGridTheme(
                    data: SfDataGridThemeData(
                      filterPopupTextStyle: GoogleFonts.lato(
                          fontSize: size.width * 0.04,
                          color: AppColors.contentColorOrange),
                    ),
                    child: SfDataGrid(
                      source: maturityDataSource,
                      key: _key,
                      columnWidthMode: ColumnWidthMode.fitByCellValue,
                      frozenColumnsCount: 1, // Number of columns to freeze
                      allowSorting: true,
                      allowFiltering: true,
                      stackedHeaderRows: <StackedHeaderRow>[
                        // set a header over all the columns, "This Month and Next Month"
                        StackedHeaderRow(cells: <StackedHeaderCell>[
                          StackedHeaderCell(
                              columnNames: [
                                'clientId',
                                'branch',
                                'names',
                                'phoneNumber',
                                'productName',
                                'loanAmount',
                                'maturingDate'
                              ],
                              child: Container(
                                color: AppColors.contentColorOrange,
                                alignment: Alignment.center,
                                child: const Text(
                                  'Loans Maturing in this month and next month Report',
                                  style: TextStyle(
                                      color: AppColors.menuBackground,
                                      fontSize: 12.0),
                                ),
                              )),
                        ]),
                      ],
                      columns: <GridColumn>[
                        GridColumn(
                            columnName: 'clientId',
                            columnWidthMode: ColumnWidthMode.fitByColumnName,
                            label: Container(
                                padding: const EdgeInsets.all(8.0),
                                alignment: Alignment.center,
                                child: const Text(
                                  'Client ID',
                                ))),
                        GridColumn(
                            columnName: 'branch',
                            columnWidthMode: ColumnWidthMode.fitByColumnName,
                            label: Container(
                                padding: const EdgeInsets.all(8.0),
                                alignment: Alignment.center,
                                child: const Text(
                                  'Branch',
                                ))),
                        GridColumn(
                            columnName: 'names',
                            columnWidthMode: ColumnWidthMode.fitByColumnName,
                            label: Container(
                                padding: const EdgeInsets.all(8.0),
                                alignment: Alignment.center,
                                child: const Text(
                                  'Names',
                                ))),
                        GridColumn(
                            columnName: 'phoneNumber',
                            columnWidthMode: ColumnWidthMode.fitByColumnName,
                            label: Container(
                                padding: const EdgeInsets.all(8.0),
                                alignment: Alignment.center,
                                child: const Text(
                                  'Phone Number',
                                ))),
                        GridColumn(
                            columnName: 'productName',
                            columnWidthMode: ColumnWidthMode.fitByColumnName,
                            label: Container(
                                padding: const EdgeInsets.all(8.0),
                                alignment: Alignment.center,
                                child: const Text(
                                  'Loan Product Name',
                                ))),
                        GridColumn(
                            columnName: 'loanAmount',
                            columnWidthMode: ColumnWidthMode.fitByColumnName,
                            label: Container(
                                padding: const EdgeInsets.all(8.0),
                                alignment: Alignment.center,
                                child: const Text(
                                  'Loan Amount',
                                ))),
                        GridColumn(
                            columnName: 'maturingDate',
                            columnWidthMode: ColumnWidthMode.fitByColumnName,
                            label: Container(
                                padding: const EdgeInsets.all(8.0),
                                alignment: Alignment.center,
                                child: const Text(
                                  'Maturing Date',
                                ))),
                      ],
                    ),
                  ),
                ),

                //add filter
              ],
            );
          }),
    );
  }

  Future<List<Maturity>> getMaturityData() async {
    try {
      AuthController authController = AuthController();

      final response = await authController.getMaturities();
      final arrearsData = response['maturities'] as List;
      final arrears = arrearsData.map((data) {
        try {
          return Maturity.fromJson(data);
        } catch (e) {
          // Consider returning a placeholder object or handling differently
          return Maturity("0", "0", "0", "0", "0", "0", "0");
        }
      }).toList();
      return arrears;
    } catch (e) {
      log(e.toString());
      return [];
    }
  }
}

/// An object to set the arrear collection data source to the datagrid. This
/// is used to map the arrear data to the datagrid widget.
class MaturityDataSource extends DataGridSource {
  /// Creates the Maturity data source class with required details.
  MaturityDataSource({required List<Maturity> maturityData}) {
    //maturity date in format "10-Aug-24" string to date format
    final DateFormat formatter = DateFormat('d-MMM-yy');

    _maturityData = maturityData
        .map<DataGridRow>((e) => DataGridRow(cells: [
              DataGridCell<String>(
                  columnName: 'clientId', value: e.id.toString()),
              DataGridCell<String>(columnName: 'branch', value: e.branch),
              DataGridCell<String>(columnName: 'names', value: e.names),
              DataGridCell<String>(
                  columnName: 'phoneNumber', value: e.phoneNumber),
              DataGridCell<String>(
                  columnName: 'productName', value: e.loanProduct),
              DataGridCell<String>(
                  columnName: 'loanAmount', value: e.loanAmount),
              DataGridCell<DateTime>(
                  columnName: 'maturingDate',
                  value: formatter.parse(e.maturityDate)),
            ]))
        .toList();
  }

  List<DataGridRow> _maturityData = [];

  @override
  List<DataGridRow> get rows => _maturityData;

  @override
  DataGridRowAdapter buildRow(DataGridRow row) {
    final formatter = NumberFormat('#,###'); // Create NumberFormat instance

    return DataGridRowAdapter(
        cells: row.getCells().map<Widget>((e) {
      if ([
        'loanAmount',
      ].contains(e.columnName)) {
        // Check if the value is numeric and can be formatted
        if (double.tryParse(e.value.toString()) != null) {
          // Format numeric values
          final formattedValue =
              formatter.format(double.parse(e.value.toString()));
          return Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.all(8.0),
            child: Text(formattedValue),
          );
        }
      }

      //convert the maturing date to date format
      if (e.columnName == 'maturingDate') {
        final date = DateTime.parse(e.value.toString());
        String formattedDate = DateFormat('yMd').format(date);
        return Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.all(8.0),
          child: Text(formattedDate),
        );
      }
      return Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.all(8.0),
        child: Text(e.value.toString()),
      );
    }).toList());
  }
}
