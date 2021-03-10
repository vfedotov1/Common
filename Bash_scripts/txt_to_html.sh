###################################################################
#<style>
#	/* Стиль таблицы (style) */
#	table.style1{text-decoration: none;border-collapse:collapse;width:100%;text-align:left;}
#	table.style1 th{font-weight:500;font-size:14px; color:#ffffff;background-color:#5690ba;}
#	table.style1 td{font-size:14px;color:#354251;}
#	table.style1 td,table.style1 th{white-space:pre-wrap;padding:11px 5px;line-height:14px;vertical-align: middle;border: 1px solid #354251;}	table.style1 tr:hover{background-color:#f9fafb}
#	table.style1 tr:hover td{color:#354251;cursor:default;}
#</style>
#<table class="style1">
#<thead>
#<tr>
#	<th>COLUMN_1</th>
#	<th>COLUMN_2</th>
#</tr>
#</thead>
#<tbody>
#<tr>
#	<td>value_col_1</td>
#	<td>value_col_2</td>
#</tr>
#<tr>
#	<td>value_col_1</td>
#	<td>value_col_2</td>
#</tr>
#</tbody>
#</table>
##################################################################
#input_txt_file should be in the following format:
#Sevice_name Growth_in_MB_per_day Stand
#AdminServer 311.417 EB
#BIP10_server 4.88291 EB
#bi_server 34.1801 EB
#CCB_server 8.10744 EB
###############################################################################
#run as ./txt_to_html.sh /tmp/input_txt_file /tmp/output_html_file "Table name"
###############################################################################
##!/bin/bash
input_txt_file=$1
output_html_file=$2
bold_message=$3
#head -1 $1 | xargs -n1 | sed "s/.*/<th>&<\/th>/" > /tmp/temp.html
#fields=$(< /tmp/temp.html)
#echo -e "$fields"
fields=$(head -1 $1 | xargs -n1 | sed "s/.*/<th>&<\/th>/")
#row=$(tail -n +2 $input_txt_file | while read LINE; do echo "<tr>" >> $output_html_file; echo $LINE | head -1 | xargs -n1 | sed "s/.*/<td>&<\/td>/" >> $output_html_file; echo "</tr>" >> $output_html_file; done)

#insert first part of html
echo "<b>${bold_message}</b>
<style>
        /* Стиль таблицы (style) */
        table.style1{text-decoration: none;border-collapse:collapse;width:100%;text-align:left;}
        table.style1 th{font-weight:500;font-size:14px; color:#ffffff;background-color:#5690ba;}
        table.style1 td{font-size:14px;color:#354251;}
        table.style1 td,table.style1 th{white-space:pre-wrap;padding:11px 5px;line-height:14px;vertical-align: middle;border: 1px solid #354251;}       table.style1 tr:hover{background-color:#f9fafb}
        table.style1 tr:hover td{color:#354251;cursor:default;}
</style>
<table class="style1">
<thead>
<tr>
${fields}
</tr>
</thead>
<tbody>" >> $output_html_file

#insert data to html
tail -n +2 $input_txt_file | while read LINE; do echo "<tr>" >> $output_html_file; echo $LINE | head -1 | xargs -n1 | sed "s/.*/<td>&<\/td>/" >> $output_html_file; echo "</tr>" >> $output_html_file; done

#close html file
echo "</tbody>
</table>" >> $output_html_file
