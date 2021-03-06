require_relative 'spec_helper'

describe 'Asciidoctor::PDF::Converter - Running Content' do
  it 'should add running footer showing virtual page number starting at body by default' do
    pdf = to_pdf <<~'EOS', attributes: {}, analyze: true
    = Document Title
    :doctype: book

    first page

    <<<

    second page

    <<<

    third page

    <<<

    fourth page
    EOS

    expected_page_numbers = %w(1 2 3 4)
    expected_x_positions = [541.009, 49.24]

    (expect pdf.pages.size).to eql 5
    page_number_texts = pdf.find_text %r/^\d+$/
    (expect page_number_texts.size).to eql expected_page_numbers.size
    page_number_texts.each_with_index do |page_number_text, idx|
      (expect page_number_text[:page_number]).to eql idx + 2
      (expect page_number_text[:x]).to eql expected_x_positions[idx.even? ? 0 : 1]
      (expect page_number_text[:y]).to eql 14.388
      (expect page_number_text[:font_size]).to eql 9
    end
  end

  it 'should not add running footer if nofooter attribute is set' do
    pdf = to_pdf <<~'EOS', attributes: 'nofooter', analyze: true
    = Document Title
    :doctype: book

    body
    EOS

    (expect pdf.find_text %r/^\d+$/).to be_empty
  end

  it 'should start running content at title page if running_content_start_at key is set to title in theme' do
    theme_overrides = { running_content_start_at: 'title' }

    pdf = to_pdf <<~'EOS', attributes: {}, theme_overrides: theme_overrides, analyze: true
    = Document Title
    :doctype: book
    :toc:

    == First Chapter

    == Second Chapter

    == Third Chapter
    EOS

    pdf.text.inject({}) {|accum, text|
      (accum[text[:page_number]] ||= []) << text
      accum
    }.each do |page_number, texts|
      last_text = texts[-1]
      (expect last_text).not_to be_nil
      (expect page_number.to_s).to eql last_text[:string]
      (expect last_text[:y]).to eql 14.388
    end
  end

  it 'should start running content at toc page if running_content_start_at key is set to toc in theme' do
    theme_overrides = { running_content_start_at: 'toc' }

    pdf = to_pdf <<~'EOS', attributes: {}, theme_overrides: theme_overrides, analyze: true
    = Document Title
    :doctype: book
    :toc:

    == First Chapter

    == Second Chapter

    == Third Chapter
    EOS

    pdf.text.inject({}) {|accum, text|
      (accum[text[:page_number]] ||= []) << text
      accum
    }.each do |page_number, texts|
      if page_number == 1
        (expect texts.size).to eql 1
      else
        last_text = texts[-1]
        (expect last_text).not_to be_nil
        (expect page_number.pred.to_s).to eql last_text[:string]
        (expect last_text[:y]).to eql 14.388
      end
    end
  end

  it 'should start running content at body if running_content_start_at key is set to toc in theme and toc is disabled' do
    theme_overrides = { running_content_start_at: 'toc' }

    pdf = to_pdf <<~'EOS', attributes: {}, theme_overrides: theme_overrides, analyze: true
    = Document Title
    :doctype: book

    == First Chapter

    == Second Chapter

    == Third Chapter
    EOS

    pdf.text.inject({}) {|accum, text|
      (accum[text[:page_number]] ||= []) << text
      accum
    }.each do |page_number, texts|
      if page_number == 1
        (expect texts.size).to eql 1
      else
        last_text = texts[-1]
        (expect last_text).not_to be_nil
        (expect page_number.pred.to_s).to eql last_text[:string]
        (expect last_text[:y]).to eql 14.388
      end
    end
  end

  it 'should add running header starting at body if header key is set in theme' do
    theme_overrides = {
      header_font_size: 9,
      header_height: 30,
      header_line_height: 1,
      header_padding: [6, 1, 0, 1],
      header_recto_right_content: '({document-title})',
      header_verso_right_content: '({document-title})'
    }

    pdf = to_pdf <<~'EOS', attributes: {}, theme_overrides: theme_overrides, analyze: true
    = Document Title
    :doctype: book

    first page

    <<<

    second page
    EOS

    expected_x_positions = [541.009, 49.24]
    expected_page_numbers = %w(1 2)

    header_texts = pdf.find_text '(Document Title)'
    (expect header_texts.size).to be expected_page_numbers.size
    expected_page_numbers.each_with_index do |page_number, idx|
      (expect header_texts[idx][:string]).to eql '(Document Title)'
      (expect header_texts[idx][:page_number]).to eql page_number.to_i + 1
      (expect header_texts[idx][:font_size]).to eql 9
    end
  end

  it 'should not add running header if noheader attribute is set' do
    theme_overrides = {
      header_font_size: 9,
      header_height: 30,
      header_line_height: 1,
      header_padding: [6, 1, 0, 1],
      header_recto_right_content: '({document-title})',
      header_verso_right_content: '({document-title})'
    }

    pdf = to_pdf <<~'EOS', attributes: 'noheader', analyze: true
    = Document Title
    :doctype: book

    body
    EOS

    (expect pdf.find_text '(Document Title)').to be_empty
  end
end
