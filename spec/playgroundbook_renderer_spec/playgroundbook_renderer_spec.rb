require File.expand_path('../../spec_helper', __FILE__)

module Playgroundbook
  describe Renderer do
    include FakeFS::SpecHelpers
    let(:renderer) { Renderer.new(yaml_file_name, contents_manifest_generator, chapter_collator, test_ui) }
    let(:yaml_file_name) { 'book.yml' }
    let(:contents_manifest_generator) { double(ContentsManifestGenerator) }
    let(:chapter_collator) { double(ChapterCollator) }
    let(:test_ui) { Cork::Board.new(silent: true) }

    before do
      File.open(yaml_file_name, 'w') do |file|
        file.write(test_book_metadata.to_yaml)
      end

      allow(contents_manifest_generator).to receive(:generate!)
      allow(chapter_collator).to receive(:collate!)
    end

    it 'initializes correctly' do
      expect(renderer.yaml_file_name) == yaml_file_name
    end

    it 'explodes when there is no playground' do
      expect{renderer.render!}.to raise_error
    end

    context 'with a playground' do
      before do
        Dir.mkdir('assets')
        FileUtils.touch('assets/file.png')
        Dir.mkdir('test_chapter.playground/')
        File.open('test_chapter.playground/Contents.swift', 'w') do |file|
          file.write('')
        end
      end

      it 'creates a directory with book name' do
        renderer.render!

        expect(Dir.exist?('Testing Book.playgroundbook')).to be_truthy
      end

      it 'creates a resources folder' do
        renderer.render!

        puts Dir.glob 'Testing Book.playgroundbook/Resources/*'
        expect(Dir.exist?('Testing Book.playgroundbook/Resources')).to be_truthy
      end

      it 'copies a resources folder contents' do
        renderer.render!
        
        expect(File.exist?('Testing Book.playgroundbook/Resources/file.png')).to be_truthy
      end

      context 'within an existing playgroundbook directory' do
        before do
          Dir.mkdir('Testing Book.playgroundbook')
        end

        it 'does not explode when the directory already exists' do
          expect { renderer.render! }.to_not raise_error
        end

        it 'creates a Contents directory within the main bundle dir' do
          renderer.render!

          expect(Dir.exist?('Testing Book.playgroundbook/Contents')).to be_truthy
        end

        context 'within the Contents directory' do
          before do
            Dir.mkdir('Testing Book.playgroundbook/Contents')
          end

          it 'does not explode when the Contents directory already exists' do
            expect { renderer.render! }.to_not raise_error
          end

          it 'renders main manifest' do
            expect(contents_manifest_generator).to receive(:generate!)

            renderer.render!
          end

          it 'creates a Chapters directory within the Contents dir' do
            renderer.render!

            expect(Dir.exist?('Testing Book.playgroundbook/Contents/Chapters')).to be_truthy
          end

          context 'within the Chapters directory' do
            before do
              Dir.mkdir('Testing Book.playgroundbook/Contents/Chapters')
            end

            it 'does not explode when the Chapters directory already exists' do
              expect { renderer.render! }.to_not raise_error
            end

            it 'generates each chapter' do
              expect(chapter_collator).to receive(:collate!)

              renderer.render!
            end
          end
        end
      end
    end
  end
end