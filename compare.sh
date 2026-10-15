root ~/rootlogon.C $1 << EOF
  .L ~/Downloads/dcb.cxx
  TCanvas *c = new TCanvas("c", "Delta X center", 1000, 700);
  int colors[] = {
      kBlack, kRed, kBlue, kGreen+2,
      kMagenta, kOrange+7, kCyan+2
  };
  const char *names[] = {
      "h_delta_${2}_center_w275",
      "h_delta_${2}_center_w300",
      "h_delta_${2}_center_w325",
      "h_delta_${2}_center_w350",
      "h_delta_${2}_center_w375",
      "h_delta_${2}_center_w400",
      "h_delta_${2}_center_w425"
  };

  TLegend *leg = new TLegend(0.70, 0.55, 0.88, 0.83);

  for (int i = 0; i < 7; i++) {
      TH1F *h = (TH1F*)_file0->Get(names[i]);
      h->Scale(1/h->Integral());
      if (!h) continue;
      h->Rebin(8);
      h->SetLineColor(colors[i]);
      if (i == 0) {
          h->Draw("l");
          h->GetXaxis()->SetRangeUser(-4, 4);
          h->GetYaxis()->SetRangeUser(0, 0.07);

          h->GetXaxis()->SetTitle("${2}_{Reco, up}^{corr} - ${2}_{Reco, down}^{corr} [mm]");
          h->GetYaxis()->SetTitle("Normalized entries");

      }
      else
          h->Draw("l SAME");
      dcb(h);  // fit DCB sull'istogramma

      leg->AddEntry(h, Form("w = %.2f", 2.75 + 0.25*i), "l");

      h->GetFunction("dcb")->SetNpx(1000);
      h->GetFunction("dcb")->SetLineColor(colors[i]);
      h->GetFunction("dcb")->SetLineWidth(1);
      cout << "sigma: " << h->GetFunction("dcb")->GetParameter(5) << "w: " << names[i] << endl;
      h->SetLineColor(colors[i]);
      h->SetMarkerColor(colors[i]);

  }
  leg->Draw();
  c->SaveAs("compare_${2}.root");
  c->SaveAs("compare_${2}.ps");

EOF
